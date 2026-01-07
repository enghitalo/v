module notify

import time
import sync

#flag windows -lws2_32
#flag -D_WIN32_WINNT=0x0600 // Windows Vista or later for WSAPoll

fn C.GetFileType(voidptr) u32
fn C.WaitForMultipleObjects(u32, &voidptr, int, u32) u32
fn C.CreateEventW(voidptr, int, int, voidptr) voidptr
fn C.ResetEvent(voidptr) int

// fn C.SetEvent(voidptr) int
// fn C.CloseHandle(voidptr) int
// fn C.PeekNamedPipe(voidptr, &u32, u32, &u32, &u32, &u32) bool
// fn C.WSAGetLastError() int
fn C.WSAEventSelect(C.intptr_t, voidptr, i32) int
fn C.WSAEnumNetworkEvents(C.intptr_t, voidptr, &WSANETWORKEVENTS) int
fn C.WSACreateEvent() voidptr
fn C.WSACloseEvent(voidptr) int

// fn C._get_osfhandle(int) C.intptr_t
// fn C.GetLastError() int
// fn C.WaitForSingleObject(voidptr, u32) u32
// fn C.GetCurrentThreadId() u32

// Network event constants
const winsock_event_read = 0x01 // FD_READ

const winsock_event_write = 0x02 // FD_WRITE

const winsock_event_oob = 0x08 // FD_OOB

const winsock_event_close = 0x20 // FD_CLOSE

const winsock_event_accept = 0x08 // FD_ACCEPT (same as OOB for server sockets)

const winsock_event_connect = 0x10 // FD_CONNECT

struct WSANETWORKEVENTS {
	l_network_events i32
	i_error_code     [10]int
}

// File type constants
const file_type_unknown = u32(0x0000)
const file_type_disk = u32(0x0001)
const file_type_char = u32(0x0002)
const file_type_pipe = u32(0x0003)

// Wait constants
const wait_object_0 = u32(0x00000000)
const wait_timeout = u32(0x00000102)
const wait_failed = u32(0xFFFFFFFF)
const wait_io_completion = u32(0x000000C0)
const infinite = u32(0xFFFFFFFF)

// Error constants
const error_io_pending = 997
const error_broken_pipe = 109
const error_no_data = 232
const error_handle_eof = 38
const error_invalid_handle = 6

struct IocpNotifier {
mut:
	fd_map        map[int]FdInfo
	wakeup_event  voidptr
	socket_events map[int]voidptr
	mtx           &sync.RwMutex = sync.new_rwmutex()
	closed        bool
	// Enhanced statistics
	stats struct {
		add_count     u64
		modify_count  u64
		remove_count  u64
		close_time    time.Time
		avg_wait_time time.Duration
		event_count   u64
		last_check    time.Time
		max_fds       int
		wait_errors   u64
	}
	// Thread ID for debugging
	creator_thread u32
}

struct FdInfo {
mut:
	handle            C.intptr_t
	events            FdEventType
	conf_flags        []FdConfigFlags
	last_ready        bool
	oneshot_triggered bool
	is_socket         bool
	socket_event      voidptr
	file_type         u32
	// For edge triggering
	pending_events FdEventType
	// For error tracking
	last_error int
}

// Production-ready FdEvent
struct IocpEvent {
pub:
	fd   int
	kind FdEventType
	// Additional context
	timestamp  time.Time
	error_code int
	// For debugging
	thread_id u32
}

const max_wait_objects = 64 // MAXIMUM_WAIT_OBJECTS

// Performance tuning
const min_poll_interval = 1 * time.millisecond
const max_poll_interval = 50 * time.millisecond
const default_poll_count = 10

// new creates a new production-ready IocpNotifier
pub fn new() !FdNotifier {
	wakeup := C.CreateEventW(unsafe { nil }, 1, 0, unsafe { nil })
	if wakeup == unsafe { nil } {
		error_code := C.GetLastError()
		return error('Failed to create wakeup event: ${error_code}')
	}

	now := time.utc()
	return &IocpNotifier{
		fd_map:         map[int]FdInfo{}
		wakeup_event:   wakeup
		socket_events:  map[int]voidptr{}
		mtx:            sync.new_rwmutex()
		closed:         false
		stats:          {
			add_count:     0
			modify_count:  0
			remove_count:  0
			close_time:    time.Time{}
			avg_wait_time: 0
			event_count:   0
			last_check:    now
			max_fds:       0
			wait_errors:   0
		}
		creator_thread: C.GetCurrentThreadId()
	}
}

fn (mut in_ IocpNotifier) wait(timeout time.Duration) []FdEvent {
	// Quick sanity check
	in_.mtx.rlock()
	if in_.closed {
		in_.mtx.runlock()
		return []FdEvent{}
	}
	in_.mtx.runlock()

	start_time := time.utc()
	mut result := []FdEvent{}

	// Handle immediate timeout
	if timeout.nanoseconds() == 0 {
		return result
	}

	// Handle infinite timeout
	mut timeout_ms := u32(infinite)
	if timeout.nanoseconds() > 0 {
		timeout_ms = u32(timeout.milliseconds())
		if timeout_ms == 0 && timeout.nanoseconds() > 0 {
			timeout_ms = 1 // Minimum 1ms
		}
	}

	// Get current state
	in_.mtx.rlock()
	total_fds := in_.fd_map.len
	in_.mtx.runlock()

	// Special case: no FDs
	if total_fds == 0 {
		return in_.wait_for_wakeup_only(timeout_ms)
	}

	// Main wait loop
	mut elapsed := time.Duration(0)
	mut poll_count := 0

	for elapsed < timeout && poll_count < default_poll_count {
		poll_start := time.utc()

		// Prepare handles for waiting
		handles, socket_map := in_.prepare_wait_handles()
		if handles.len == 0 {
			time.sleep(min_poll_interval)
			elapsed = time.utc() - start_time
			poll_count++
			continue
		}

		// Wait for events
		wait_result := C.WaitForMultipleObjects(u32(handles.len), handles.data, false, // Wait for any
		 timeout_ms)

		wait_duration := time.utc() - poll_start
		in_.update_wait_stats(wait_duration)

		if wait_result == wait_object_0 {
			// Wakeup event - reset and continue
			C.ResetEvent(in_.wakeup_event)

			// Check if we should break
			in_.mtx.rlock()
			new_total_fds := in_.fd_map.len
			in_.mtx.runlock()

			if new_total_fds == 0 {
				break
			}

			// Process any immediate events
			immediate_events := in_.check_immediate_events()
			if immediate_events.len > 0 {
				result << immediate_events
				break
			}
		} else if wait_result >= wait_object_0 + 1 && wait_result < wait_object_0 + handles.len {
			// Socket event
			event_index := int(wait_result - wait_object_0 - 1)
			socket_events := in_.process_socket_event_at_index(event_index, socket_map)
			if socket_events.len > 0 {
				result << socket_events

				// Also check for pipe events
				pipe_events := in_.check_pipe_events()
				if pipe_events.len > 0 {
					result << pipe_events
				}

				break
			}
		} else if wait_result == wait_timeout {
			// Timeout - check for pipe events
			pipe_events := in_.check_pipe_events()
			if pipe_events.len > 0 {
				result << pipe_events
				break
			}
		} else if wait_result == wait_failed {
			// Error
			error_code := C.GetLastError()
			in_.stats.wait_errors++

			// Log but don't crash
			if error_code != 0 {
				// eprintln('WaitForMultipleObjects failed: ${error_code}')
			}

			// Small delay to prevent tight loop
			time.sleep(10 * time.millisecond)
		}

		elapsed = time.utc() - start_time
		poll_count++

		// Calculate remaining timeout
		if timeout.nanoseconds() > 0 {
			remaining := timeout - elapsed
			if remaining.nanoseconds() <= 0 {
				break
			}
			timeout_ms = u32(remaining.milliseconds())
			if timeout_ms == 0 && remaining.nanoseconds() > 0 {
				timeout_ms = 1
			}
		}
	}

	// Apply post-processing
	if result.len > 0 {
		in_.apply_post_wait_updates(result)
		in_.stats.event_count += u64(result.len)
	}

	return result
}

fn (mut in_ IocpNotifier) wait_for_wakeup_only(timeout_ms u32) []FdEvent {
	if in_.wakeup_event == 0 {
		return []FdEvent{}
	}

	handles := []voidptr{len: 1}
	handles[0] = in_.wakeup_event

	wait_result := C.WaitForMultipleObjects(1, handles.data, false, timeout_ms)
	if wait_result == wait_object_0 {
		C.ResetEvent(in_.wakeup_event)
	}

	return []FdEvent{}
}

fn (mut in_ IocpNotifier) prepare_wait_handles() ([]voidptr, map[int]int) {
	in_.mtx.rlock()
	defer { in_.mtx.runlock() }

	mut handles := []voidptr{cap: max_wait_objects}
	mut socket_map := map[int]int{}

	// Add wakeup event
	handles << in_.wakeup_event

	// Add socket events
	mut count := 1
	for fd, info in in_.fd_map {
		if count >= max_wait_objects {
			break
		}

		if info.is_socket && info.socket_event != 0 && !in_.should_skip_socket(info) {
			socket_map[count] = fd
			handles << info.socket_event
			count++
		}
	}

	return handles, socket_map
}

fn (mut in_ IocpNotifier) should_skip_socket(info &FdInfo) bool {
	if has_flag(info.conf_flags, .one_shot) && info.oneshot_triggered {
		return true
	}

	if info.events.is_empty() {
		return true
	}

	return false
}

fn (mut in_ IocpNotifier) process_socket_event_at_index(index int, socket_map map[int]int) []FdEvent {
	mut result := []FdEvent{}

	in_.mtx.rlock()
	fd := socket_map[index] or {
		in_.mtx.runlock()
		return result
	}

	info := in_.fd_map[fd] or {
		in_.mtx.runlock()
		return result
	}
	in_.mtx.runlock()

	// Process the socket event
	network_events := WSANETWORKEVENTS{}
	if C.WSAEnumNetworkEvents(info.handle, info.socket_event, &network_events) == 0 {
		mut current_events := unsafe { FdEventType(0) }

		// Map network events to our event types
		if network_events.l_network_events & winsock_event_read != 0 && info.events.has(.read) {
			current_events.set(.read)
		}
		if network_events.l_network_events & winsock_event_write != 0 && info.events.has(.write) {
			current_events.set(.write)
		}
		if network_events.l_network_events & winsock_event_oob != 0 && info.events.has(.exception) {
			current_events.set(.exception)
		}
		if network_events.l_network_events & winsock_event_close != 0 {
			current_events.set(.hangup)
		}

		// Check for errors
		mut error_event := unsafe { FdEventType(0) }
		for i in 0 .. 10 {
			if network_events.i_error_code[i] != 0 {
				error_event.set(.error)
				break
			}
		}

		if !current_events.is_empty() || !error_event.is_empty() {
			current_thread := C.GetCurrentThreadId()

			if !current_events.is_empty() {
				result << IocpEvent{
					fd:         fd
					kind:       current_events
					timestamp:  time.utc()
					error_code: 0
					thread_id:  current_thread
				}
			}

			if !error_event.is_empty() {
				result << IocpEvent{
					fd:         fd
					kind:       error_event
					timestamp:  time.utc()
					error_code: network_events.i_error_code[0]
					thread_id:  current_thread
				}
			}
		}
	}

	return result
}

fn (mut in_ IocpNotifier) check_pipe_events() []FdEvent {
	mut result := []FdEvent{}

	in_.mtx.rlock()
	defer { in_.mtx.runlock() }

	for fd, mut info in in_.fd_map {
		if info.is_socket {
			continue
		}

		// Skip if one-shot already triggered
		if has_flag(info.conf_flags, .one_shot) && info.oneshot_triggered {
			continue
		}

		mut current_events := unsafe { FdEventType(0) }

		// Check readability
		if info.events.has(.read)
			&& (info.file_type == file_type_pipe || info.file_type == file_type_char) {
			if in_.is_pipe_readable(info.handle) {
				current_events.set(.read)
			}
		}

		// Check writability
		if info.events.has(.write) {
			if in_.is_handle_writable(info.handle, info.file_type) {
				current_events.set(.write)
			}
		}

		// Check for closure
		if info.events.has(.hangup) || info.events.has(.peer_hangup) {
			if in_.is_handle_closed(info.handle, info.file_type) {
				current_events.set(.hangup)
			}
		}

		// Handle edge triggering
		if has_flag(info.conf_flags, .edge_trigger) {
			is_ready := !current_events.is_empty()
			if is_ready && !info.last_ready {
				// Rising edge
				info.last_ready = true
				current_thread := C.GetCurrentThreadId()
				result << IocpEvent{
					fd:         fd
					kind:       current_events
					timestamp:  time.utc()
					error_code: 0
					thread_id:  current_thread
				}
			} else if !is_ready {
				// Falling edge
				info.last_ready = false
			}
			// Don't add event if already reported
		} else if !current_events.is_empty() {
			// Level-triggered
			current_thread := C.GetCurrentThreadId()
			result << IocpEvent{
				fd:         fd
				kind:       current_events
				timestamp:  time.utc()
				error_code: 0
				thread_id:  current_thread
			}
		}
	}

	return result
}

fn (mut in_ IocpNotifier) check_immediate_events() []FdEvent {
	mut result := []FdEvent{}

	in_.mtx.rlock()
	defer { in_.mtx.runlock() }

	// Check all sockets without waiting
	for fd, info in in_.fd_map {
		if !info.is_socket || info.socket_event == 0 {
			continue
		}

		wait_result := C.WaitForSingleObject(info.socket_event, 0)
		if wait_result == wait_object_0 {
			// Process immediately
			network_events := WSANETWORKEVENTS{}
			if C.WSAEnumNetworkEvents(info.handle, info.socket_event, &network_events) == 0 {
				mut current_events := unsafe { FdEventType(0) }

				if network_events.l_network_events & winsock_event_read != 0
					&& info.events.has(.read) {
					current_events.set(.read)
				}
				if network_events.l_network_events & winsock_event_write != 0
					&& info.events.has(.write) {
					current_events.set(.write)
				}
				if network_events.l_network_events & winsock_event_close != 0 {
					current_events.set(.hangup)
				}

				if !current_events.is_empty() {
					current_thread := C.GetCurrentThreadId()
					result << IocpEvent{
						fd:         fd
						kind:       current_events
						timestamp:  time.utc()
						error_code: 0
						thread_id:  current_thread
					}
				}
			}
		}
	}

	return result
}

fn (mut in_ IocpNotifier) apply_post_wait_updates(events []FdEvent) {
	in_.mtx.lock()
	defer { in_.mtx.unlock() }

	for event in events {
		if info := in_.fd_map[event.fd] {
			mut updated_info := info

			// Update oneshot flag
			if has_flag(info.conf_flags, .one_shot) {
				updated_info.oneshot_triggered = true
			}

			// Clear pending events for edge triggering
			if has_flag(info.conf_flags, .edge_trigger) {
				updated_info.pending_events = unsafe { FdEventType(0) }
			}

			// Update error code
			if event.error_code != 0 {
				updated_info.last_error = event.error_code
			}

			in_.fd_map[event.fd] = updated_info
		}
	}
}

fn (mut in_ IocpNotifier) update_wait_stats(wait_duration time.Duration) {
	// Simple exponential moving average
	alpha := 0.2
	if in_.stats.avg_wait_time == 0 {
		in_.stats.avg_wait_time = wait_duration
	} else {
		avg_ns := f64(in_.stats.avg_wait_time.nanoseconds())
		wait_ns := f64(wait_duration.nanoseconds())
		new_avg_ns := alpha * wait_ns + (1 - alpha) * avg_ns
		in_.stats.avg_wait_time = time.Duration(i64(new_avg_ns))
	}

	// Periodic reset
	now := time.utc()
	if now - in_.stats.last_check > 30 * time.second {
		in_.stats.event_count = 0
		in_.stats.wait_errors = 0
		in_.stats.last_check = now
	}
}

fn (mut in_ IocpNotifier) is_pipe_readable(handle C.intptr_t) bool {
	mut bytes_avail := u32(0)
	mut bytes_left := u32(0)
	mut total_bytes := u32(0)

	result := C.PeekNamedPipe(handle, unsafe { nil }, 0, unsafe { nil }, &bytes_avail,
		&bytes_left)

	// Check if pipe has data or is at EOF
	if result != false {
		if bytes_avail > 0 {
			return true
		}
		// Check if pipe is at EOF (bytes_left == 0 for read handle)
		if bytes_left == 0 {
			return true // EOF is "readable" as a hangup event
		}
	}

	return false
}

fn (mut in_ IocpNotifier) is_handle_writable(handle C.intptr_t, file_type u32) bool {
	if file_type == file_type_pipe {
		// For pipes, check if write would succeed
		mut bytes_avail := u32(0)
		result := C.PeekNamedPipe(handle, unsafe { nil }, 0, unsafe { nil }, &bytes_avail,
			unsafe { nil })
		return result != false
	}

	// For other handle types, assume writable
	return true
}

fn (mut in_ IocpNotifier) is_handle_closed(handle C.intptr_t, file_type u32) bool {
	// Check if handle is invalid
	file_type_check := C.GetFileType(handle)
	if file_type_check == file_type_unknown {
		return true
	}

	// For pipes, check if broken
	if file_type == file_type_pipe {
		mut bytes_avail := u32(0)
		result := C.PeekNamedPipe(handle, unsafe { nil }, 0, unsafe { nil }, &bytes_avail,
			unsafe { nil })
		if result == false {
			error_code := C.GetLastError()
			return error_code == error_broken_pipe || error_code == error_no_data
		}
	}

	return false
}

fn (mut in_ IocpNotifier) add(fd int, events FdEventType, conf ...FdConfigFlags) ! {
	// Quick validation
	if fd < 0 {
		return error('Invalid file descriptor: ${fd}')
	}

	handle := C._get_osfhandle(fd)
	if handle == C.intptr_t(-1) {
		return error('Invalid file descriptor: ${fd}')
	}

	if events.is_empty() {
		return error('No events specified')
	}

	in_.mtx.lock()
	defer {
		in_.mtx.unlock()
		in_.signal_wakeup()
	}

	if in_.closed {
		return error('Notifier is closed')
	}

	if fd in in_.fd_map {
		return error('File descriptor already registered: ${fd}')
	}

	// Get file type and determine if it's a socket
	file_type := C.GetFileType(handle)
	mut is_socket := false
	mut socket_event := unsafe { nil }

	// Try to set up socket event if it looks like a socket
	if file_type == file_type_unknown || file_type == 0 {
		socket_event = C.WSACreateEvent()
		if socket_event == 0 {
			return error('Failed to create socket event')
		}

		// Build event mask
		mut event_mask := i32(0)
		if events.has(.read) {
			event_mask |= i32(winsock_event_read)
		}
		if events.has(.write) {
			event_mask |= i32(winsock_event_write)
		}
		if events.has(.exception) {
			event_mask |= i32(winsock_event_oob)
		}
		if events.has(.hangup) || events.has(.peer_hangup) || events.has(.error) {
			event_mask |= i32(winsock_event_close)
		}

		// Always monitor closure
		if event_mask == 0 {
			event_mask = i32(winsock_event_close)
		}

		result := C.WSAEventSelect(handle, socket_event, event_mask)
		if result != 0 {
			error_code := C.WSAGetLastError()
			C.WSACloseEvent(socket_event)
			return error('WSAEventSelect failed: ${error_code}')
		}

		is_socket = true
		in_.socket_events[fd] = socket_event
	}

	// Create and store info
	info := FdInfo{
		handle:            handle
		events:            events
		conf_flags:        conf.clone()
		last_ready:        false
		oneshot_triggered: false
		is_socket:         is_socket
		socket_event:      socket_event
		file_type:         file_type
		pending_events:    unsafe { FdEventType(0) }
		last_error:        0
	}

	in_.fd_map[fd] = info
	in_.stats.add_count++

	// Update max FDs
	if in_.fd_map.len > in_.stats.max_fds {
		in_.stats.max_fds = in_.fd_map.len
	}
}

fn (mut in_ IocpNotifier) modify(fd int, events FdEventType, conf ...FdConfigFlags) ! {
	if events.is_empty() {
		return error('No events specified')
	}

	in_.mtx.lock()
	defer {
		in_.mtx.unlock()
		in_.signal_wakeup()
	}

	if in_.closed {
		return error('Notifier is closed')
	}

	if fd !in in_.fd_map {
		return error('File descriptor not found: ${fd}')
	}

	mut info := in_.fd_map[fd] or { return error('File descriptor not found') }

	// Update socket event mask if it's a socket
	if info.is_socket && info.socket_event != 0 {
		mut event_mask := i32(0)
		if events.has(.read) {
			event_mask |= i32(winsock_event_read)
		}
		if events.has(.write) {
			event_mask |= i32(winsock_event_write)
		}
		if events.has(.exception) {
			event_mask |= i32(winsock_event_oob)
		}
		if events.has(.hangup) || events.has(.peer_hangup) || events.has(.error) {
			event_mask |= i32(winsock_event_close)
		}

		if event_mask == 0 {
			event_mask = i32(winsock_event_close)
		}

		result := C.WSAEventSelect(info.handle, info.socket_event, event_mask)
		if result != 0 {
			return error('Failed to update socket events')
		}
	}

	// Update info
	info.events = events
	info.conf_flags = conf.clone()
	info.oneshot_triggered = false
	info.pending_events = unsafe { FdEventType(0) }

	in_.fd_map[fd] = info
	in_.stats.modify_count++
}

fn (mut in_ IocpNotifier) remove(fd int) ! {
	in_.mtx.lock()
	defer {
		in_.mtx.unlock()
		in_.signal_wakeup()
	}

	if fd !in in_.fd_map {
		return error('File descriptor not found: ${fd}')
	}

	info := in_.fd_map[fd] or { return error('File descriptor not found') }

	// Clean up socket event
	if fd in in_.socket_events {
		event := in_.socket_events[fd]
		if event != 0 {
			if info.is_socket {
				C.WSAEventSelect(info.handle, event, 0)
				C.WSACloseEvent(event)
			} else {
				C.CloseHandle(event)
			}
		}
		in_.socket_events.delete(fd)
	}

	// Remove from map
	in_.fd_map.delete(fd)
	in_.stats.remove_count++
}

fn (mut in_ IocpNotifier) close() ! {
	in_.mtx.lock()
	defer { in_.mtx.unlock() }

	if in_.closed {
		return
	}

	in_.closed = true
	in_.stats.close_time = time.utc()

	// Clean up socket events
	for fd, event in in_.socket_events {
		if event != 0 {
			C.WSACloseEvent(event)
		}
	}
	in_.socket_events.clear()

	// Clear maps
	in_.fd_map.clear()

	// Close wakeup event
	if in_.wakeup_event != 0 {
		C.CloseHandle(in_.wakeup_event)
		in_.wakeup_event = unsafe { nil }
	}
}

fn (mut in_ IocpNotifier) signal_wakeup() {
	if in_.wakeup_event != 0 {
		current_state := C.WaitForSingleObject(in_.wakeup_event, 0)
		if current_state != wait_object_0 {
			C.SetEvent(in_.wakeup_event)
		}
	}
}

fn has_flag(flags []FdConfigFlags, flag FdConfigFlags) bool {
	for f in flags {
		if f.has(flag) {
			return true
		}
	}
	return false
}
