# os.notify - File Descriptor Event Notification

The `os.notify` module provides cross-platform file descriptor event notification using the best available mechanism for each platform:
- **Linux**: epoll
- **macOS/BSD**: kqueue
- **Other platforms**: Not yet supported

## Usage

```v
import os
import os.notify

mut notifier := notify.new()!
defer {
    notifier.close() or {}
}

// Add a file descriptor to watch for read events
notifier.add(fd, .read)!

// Wait for events (with timeout)
events := notifier.wait(100 * time.millisecond)
for event in events {
    if event.kind.has(.read) {
        // Handle read event
    }
}
```

## Event Types

- `.read` - Data is available to read
- `.write` - File descriptor is ready for writing
- `.peer_hangup` - Peer closed the connection (Linux only)
- `.exception` - Exceptional condition on file descriptor
- `.error` - Error occurred (Linux only)
- `.hangup` - Hangup occurred (Linux only)

## Configuration Flags

- `.edge_trigger` - Edge-triggered notifications (note: behavior differs between Linux and macOS)
- `.one_shot` - Event is disabled after first notification
- `.wake_up` - System wake-up event (Linux only)
- `.exclusive` - Exclusive wake-up (Linux only)

## Platform Differences

### macOS/kqueue vs Linux/epoll

**Event Type Support:**
- macOS kqueue does **not** support: `.peer_hangup`, `.error`, `.hangup`
- Linux epoll supports all event types

**Configuration Flags:**
- macOS kqueue does **not** support: `.wake_up`, `.exclusive`
- Linux epoll supports all configuration flags

**Edge Trigger Behavior:**
- Linux epoll (`EPOLLET`): Triggers once when state changes from unreadable to readable
- macOS kqueue (`EV_CLEAR`): May trigger multiple times even if data is not completely read

When using unsupported features on macOS, the methods will return an error instead of panicking, allowing for graceful degradation.

## Error Handling

All methods that can fail return a `Result` type. Handle errors appropriately:

```v
notifier.add(fd, .read) or {
    eprintln('Failed to add fd: ${err}')
    return
}
```

On macOS, attempting to use unsupported features will return an error:

```v
// This will fail on macOS with an error message
notifier.add(fd, .hangup) or {
    eprintln('Error: ${err}') // "kqueue does not support 'hangup' event type"
}
```

## Thread Safety

Both `EpollNotifier` (Linux) and `KqueueNotifier` (macOS) use fixed-size arrays for event storage, making them thread-safe for concurrent use.
