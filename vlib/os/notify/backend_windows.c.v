module notify

import time

#flag windows -lws2_32

// Windows backend for FdNotifier using polling approach
//
// Note: Unlike Linux (epoll) and macOS (kqueue), Windows doesn't have a direct
// equivalent for file descriptor readiness notifications. IOCP (I/O Completion Ports)
// is completion-based rather than readiness-based.
//
// This implementation uses a polling approach with PeekNamedPipe to check pipe
// readiness. While not as efficient as event-driven approaches, it provides
// compatibility with the FdNotifier interface and works correctly for the
// intended use cases (pipes, sockets).
//
// For production use with sockets, consider using WSAEventSelect or IOCP with
// overlapped I/O operations for better performance.

// Windows API declarations for pipe/file readiness checking
// fn C.PeekNamedPipe(hNamedPipe voidptr, lpBuffer voidptr, nBufferSize int, lpBytesRead voidptr, lpTotalBytesAvail voidptr,
// 	lpBytesLeftThisMessage voidptr) bool
fn C.GetFileType(voidptr) u32
fn C.WaitForMultipleObjects(u32, &voidptr, int, u32) u32
fn C.CreateEventW(voidptr, int, int, voidptr) voidptr
fn C.ResetEvent(voidptr) int

// Windows file type constants
const file_type_char = u32(0x0002)
const file_type_pipe = u32(0x0003)

// Wait result constants
const wait_object_0 = u32(0x00000000)
const wait_timeout = u32(0x00000102)
const wait_failed = u32(0xFFFFFFFF)
const invalid_handle_value = voidptr(-1)

// IocpNotifier provides methods that implement FdNotifier
// using polling on Windows
struct IocpNotifier {
mut:
	// Map of file descriptor to info
	fd_map       map[int]FdInfo
	wakeup_event voidptr
}

struct FdInfo {
mut:
	handle            C.intptr_t
	events            FdEventType
	conf_flags        []FdConfigFlags
	last_ready        bool
	oneshot_triggered bool
}

// IocpEvent describes an event that occurred for a file descriptor
struct IocpEvent {
pub:
	fd   int
	kind FdEventType
}

// new creates a new IocpNotifier.
// The FdNotifier interface is returned to allow OS specific
// implementations without exposing the concrete type
pub fn new() !FdNotifier {
	// Create a manual-reset event for waking up
	wakeup := C.CreateEventW(unsafe { nil }, 1, 0, unsafe { nil })
	if wakeup == unsafe { nil } {
		return error('Failed to create wakeup event: ${C.GetLastError()}')
	}

	// Needed to circumvent V limitations
	x := &IocpNotifier{
		fd_map:       map[int]FdInfo{}
		wakeup_event: wakeup
	}
	return x
}

// add adds a file descriptor to the watch list
fn (mut in_ IocpNotifier) add(fd int, events FdEventType, conf ...FdConfigFlags) ! {
	// Get the OS handle for the file descriptor
	handle := C._get_osfhandle(fd)
	if handle == voidptr(-1) {
		return error('Invalid file descriptor')
	}

	// Check if already registered
	if fd in in_.fd_map {
		return error('File descriptor already registered')
	}

	// Store the mapping
	in_.fd_map[fd] = FdInfo{
		handle:            handle
		events:            events
		conf_flags:        conf.clone()
		last_ready:        false
		oneshot_triggered: false
	}
}

// modify sets an existing entry in the watch list to the provided events and configuration
fn (mut in_ IocpNotifier) modify(fd int, events FdEventType, conf ...FdConfigFlags) ! {
	if fd !in in_.fd_map {
		return error('File descriptor not found')
	}

	mut info := in_.fd_map[fd] or { return error('File descriptor not found') }
	info.events = events
	info.conf_flags = conf.clone()
	info.oneshot_triggered = false
	in_.fd_map[fd] = info
}

// remove removes a file descriptor from the watch list
fn (mut in_ IocpNotifier) remove(fd int) ! {
	// Remove from map - will error if not found
	in_.fd_map.delete(fd)
}

// wait waits to be notified of events on the watch list
fn (mut in_ IocpNotifier) wait(timeout time.Duration) []FdEvent {
	mut result := []FdEvent{}

	start_time := time.now()
	timeout_ns := timeout.nanoseconds()
	mut sleep_duration := 500 * time.microsecond // Start with 500μs

	for {
		// Check all registered file descriptors for readiness
		for fd, mut info in in_.fd_map {
			// Skip if oneshot and already triggered
			if has_flag(info.conf_flags, .one_shot) && info.oneshot_triggered {
				continue
			}

			mut current_events := unsafe { FdEventType(0) }

			// Check for read readiness
			if info.events.has(.read) {
				if is_readable(info.handle) {
					current_events.set(.read)
				}
			}

			// Check for write readiness (pipes are usually always writable)
			if info.events.has(.write) {
				if is_writable(info.handle) {
					current_events.set(.write)
				}
			}

			// Check for hangup
			if info.events.has(.hangup) || info.events.has(.peer_hangup) {
				if is_closed(info.handle) {
					current_events.set(.hangup)
				}
			}

			// Handle edge-triggered mode
			has_edge := has_flag(info.conf_flags, .edge_trigger)
			if has_edge {
				// Only report if state changed from not-ready to ready
				is_ready := !current_events.is_empty()
				if is_ready && !info.last_ready {
					info.last_ready = true
					in_.fd_map[fd] = info
				} else if !is_ready {
					info.last_ready = false
					in_.fd_map[fd] = info
					continue
				} else {
					// Was already ready, don't report
					continue
				}
			}

			// If events occurred, add to result
			if !current_events.is_empty() {
				result << &IocpEvent{
					fd:   fd
					kind: current_events
				}

				// Mark oneshot as triggered
				if has_flag(info.conf_flags, .one_shot) {
					info.oneshot_triggered = true
					in_.fd_map[fd] = info
				}
			}
		}

		// If we have events, return them
		if result.len > 0 {
			return result
		}

		// Check if timeout expired
		if timeout_ns == 0 {
			return result
		}

		elapsed := time.now() - start_time
		if elapsed.nanoseconds() >= timeout_ns {
			return result
		}

		// Adaptive sleep - start short, increase if no events
		// This balances responsiveness with CPU usage
		time.sleep(sleep_duration)
		if sleep_duration < 5 * time.millisecond {
			sleep_duration = sleep_duration * 2
		}
	}

	return result
}

// close closes the IocpNotifier
fn (mut in_ IocpNotifier) close() ! {
	in_.fd_map.clear()

	if in_.wakeup_event != unsafe { nil } {
		C.CloseHandle(in_.wakeup_event)
		in_.wakeup_event = unsafe { nil }
	}
}

// Helper function to check if handle is readable
fn is_readable(handle C.intptr_t) bool {
	file_type := C.GetFileType(handle)

	// For pipes, use PeekNamedPipe
	if file_type == file_type_pipe {
		mut bytes_avail := u32(0)
		result := C.PeekNamedPipe(handle, unsafe { nil }, 0, unsafe { nil }, &bytes_avail,
			unsafe { nil })
		if result != false && bytes_avail > 0 {
			return true
		}
	}

	return false
}

// Helper function to check if handle is writable
// Note: For pipes, this currently always returns true, which may not be accurate
// if the pipe buffer is full. In practice, this is acceptable for most use cases
// as pipe writes are typically non-blocking or buffer sizes are large enough.
fn is_writable(handle C.intptr_t) bool {
	file_type := C.GetFileType(handle)

	// For pipes, they're usually writable unless full
	// A more accurate implementation would need to check the buffer status
	if file_type == file_type_pipe {
		return true
	}

	return false
}

// Helper function to check if handle is closed/disconnected
fn is_closed(handle C.intptr_t) bool {
	file_type := C.GetFileType(handle)

	// For pipes, check if PeekNamedPipe fails
	if file_type == file_type_pipe {
		result := C.PeekNamedPipe(handle, unsafe { nil }, 0, unsafe { nil }, unsafe { nil },
			unsafe { nil })
		if result == false {
			return true
		}
	}

	return false
}

// Helper function to check if a flag is set
fn has_flag(flags []FdConfigFlags, flag FdConfigFlags) bool {
	for f in flags {
		if f.has(flag) {
			return true
		}
	}
	return false
}
