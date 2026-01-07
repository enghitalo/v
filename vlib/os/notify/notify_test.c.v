// vtest flaky: true
// vtest retry: 3
import os
import os.notify

// make a pipe and return the (read, write) file descriptors
fn make_pipe() !(int, int) {
	$if linux || macos {
		pipefd := [2]int{}
		if C.pipe(&pipefd[0]) != 0 {
			return error('error ${C.errno}: ' + os.posix_get_error_msg(C.errno))
		}
		return pipefd[0], pipefd[1]
	}
	return -1, -1
}

// test_level_trigger tests level-triggered mode where events continue
// to be reported as long as the condition persists (e.g., data available to read)
fn test_level_trigger() {
	// currently only linux and macos are supported
	$if linux || macos {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			os.fd_close(writer)
			notifier.close() or {}
		}
		notifier.add(reader, .read)!

		os.fd_write(writer, 'foobar')
		mut n := &notifier
		check_read_event(mut n, reader, 'foo')
		check_read_event(mut n, reader, 'bar')

		assert notifier.wait(0).len == 0
	}
}

// test_edge_trigger tests edge-triggered mode where events are only
// reported when the state changes. Note: behavior differs between platforms.
fn test_edge_trigger() {
	// currently only linux and macos are supported
	$if linux || macos {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			os.fd_close(writer)
			notifier.close() or {}
		}
		notifier.add(reader, .read, .edge_trigger)!

		mut n := &notifier

		os.fd_write(writer, 'foobar')
		check_read_event(mut n, reader, 'foo')

		$if linux {
			assert notifier.wait(0).len == 0
		}
		$if macos {
			/*
			In the kqueue of macos, EV_CLEAR flag represents a clear event,
			which is mainly used for pipeline and socket class events. When this flag is set,
			kqueue will trigger the corresponding event when the data is readable or writable,
			but it is not guaranteed that the event will only be triggered once.
			Compared to EPOLLET, EV_CLEAR's behavior varies. In epoll, the edge triggered mode only triggers
			an event once when the state changes from unreadable/non writable to readable/writable,
			that is, when the data changes from unreadable to readable,
			or when the data changes from unreadable to writable. In the kqueue of macos,
			EV_CLEAR does not possess this precise edge triggering behavior.
			Therefore, in the kqueue of macos, even if the data is not completely read,
			it is possible to continue triggering read events. This means that if you don't process all the data,
			the next kqueue event notification may still be triggered
			*/

			// notifier.wait(0).len == 1 or 0
		}

		os.fd_write(writer, 'baz')
		// we do not get an event because there is still data
		// to be read
		// assert notifier.wait(0).len == 0
		// TODO: investigage why the above assert suddenly started failing on the latest Ubuntu kernel update:
		// 5.11.0-37-generic #41~20.04.2-Ubuntu SMP Fri Sep 24 09:06:38 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
	}
}

// test_one_shot tests one-shot mode where an event is only reported once
// and then must be re-armed to receive further notifications
fn test_one_shot() {
	$if linux || macos {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			os.fd_close(writer)
			notifier.close() or {}
		}
		notifier.add(reader, .read, .one_shot)!

		mut n := &notifier

		os.fd_write(writer, 'foobar')
		check_read_event(mut n, reader, 'foo')
		os.fd_write(writer, 'baz')

		assert notifier.wait(0).len == 0

		// rearm
		notifier.modify(reader, .read)!
		check_read_event(mut n, reader, 'barbaz')
	}
}

// test_hangup tests hangup event detection (Linux only - kqueue doesn't support it)
fn test_hangup() {
	$if linux {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			notifier.close() or {}
		}
		notifier.add(reader, .hangup)!

		assert notifier.wait(0).len == 0

		// closing on the writer end of the pipe will
		// cause a hangup on the reader end
		os.fd_close(writer)
		events := notifier.wait(0)
		assert events.len == 1
		assert events[0].fd == reader
		assert events[0].kind.has(.hangup)
	}
}

// test_write tests write readiness notification
fn test_write() {
	$if linux || macos {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			os.fd_close(writer)
			notifier.close() or {}
		}

		notifier.add(reader, .write)!
		assert notifier.wait(0).len == 0

		notifier.add(writer, .write)!
		events := notifier.wait(0)
		assert events.len == 1
		assert events[0].fd == writer
		assert events[0].kind.has(.write)
	}
}

// test_remove tests removing a file descriptor from the watch list
fn test_remove() {
	$if linux || macos {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			os.fd_close(writer)
			notifier.close() or {}
		}

		// level triggered - will keep getting events while
		// there is data to read
		notifier.add(reader, .read)!
		os.fd_write(writer, 'foobar')
		assert notifier.wait(0).len == 1
		assert notifier.wait(0).len == 1

		notifier.remove(reader)!
		assert notifier.wait(0).len == 0
	}
}

fn check_read_event(mut notifier notify.FdNotifier, reader_fd int, expected string) {
	events := notifier.wait(0)
	assert events.len == 1
	assert events[0].fd == reader_fd
	assert events[0].kind.has(.read)
	s, _ := os.fd_read(events[0].fd, expected.len)
	assert s == expected
}

// Test that unsupported event types on macOS return proper errors instead of panicking
fn test_unsupported_event_types_on_macos() {
	$if macos {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			os.fd_close(writer)
			notifier.close() or {}
		}

		// Test that peer_hangup is not supported
		if _ := notifier.add(reader, .peer_hangup) {
			assert false, 'peer_hangup should not be supported on macOS'
		} else {
			// Expected error
			assert err.msg().contains('peer_hangup')
		}

		// Test that error event type is not supported
		if _ := notifier.add(reader, .error) {
			assert false, 'error event type should not be supported on macOS'
		} else {
			// Expected error
			assert err.msg().contains('error')
		}

		// Test that hangup is not supported
		if _ := notifier.add(reader, .hangup) {
			assert false, 'hangup should not be supported on macOS'
		} else {
			// Expected error
			assert err.msg().contains('hangup')
		}
	}
}

// Test that unsupported config flags on macOS return proper errors instead of panicking
fn test_unsupported_config_flags_on_macos() {
	$if macos {
		mut notifier := notify.new()!
		reader, writer := make_pipe()!
		defer {
			os.fd_close(reader)
			os.fd_close(writer)
			notifier.close() or {}
		}

		// Test that wake_up flag is not supported
		if _ := notifier.add(reader, .read, .wake_up) {
			assert false, 'wake_up flag should not be supported on macOS'
		} else {
			// Expected error
			assert err.msg().contains('wake_up')
		}

		// Test that exclusive flag is not supported
		if _ := notifier.add(reader, .read, .exclusive) {
			assert false, 'exclusive flag should not be supported on macOS'
		} else {
			// Expected error
			assert err.msg().contains('exclusive')
		}
	}
}

// Test multiple file descriptors on macOS
fn test_multiple_fds_macos() {
	$if macos {
		mut notifier := notify.new()!
		reader1, writer1 := make_pipe()!
		reader2, writer2 := make_pipe()!
		defer {
			os.fd_close(reader1)
			os.fd_close(writer1)
			os.fd_close(reader2)
			os.fd_close(writer2)
			notifier.close() or {}
		}

		notifier.add(reader1, .read)!
		notifier.add(reader2, .read)!

		// Write to both pipes
		os.fd_write(writer1, 'pipe1')
		os.fd_write(writer2, 'pipe2')

		// Should get events from both
		events := notifier.wait(0)
		assert events.len == 2
		
		// Read from both to verify
		for event in events {
			if event.fd == reader1 {
				s, _ := os.fd_read(event.fd, 5)
				assert s == 'pipe1'
			} else if event.fd == reader2 {
				s, _ := os.fd_read(event.fd, 5)
				assert s == 'pipe2'
			}
		}
	}
}
