# Cross-Platform Usage Example for os.notify

This example demonstrates how to write cross-platform code using `os.notify` that gracefully handles platform differences.

```v
import os
import os.notify
import time

fn main() {
    mut notifier := notify.new() or {
        eprintln('Failed to create notifier: ${err}')
        return
    }
    defer {
        notifier.close() or {}
    }

    // Create a pipe for demonstration
    pipefd := [2]int{}
    if C.pipe(&pipefd[0]) != 0 {
        eprintln('Failed to create pipe')
        return
    }
    reader, writer := pipefd[0], pipefd[1]
    defer {
        os.fd_close(reader)
        os.fd_close(writer)
    }

    // Add read event - works on all platforms
    notifier.add(reader, .read) or {
        eprintln('Failed to add reader: ${err}')
        return
    }

    // Try to add peer_hangup - will fail on macOS, succeed on Linux
    notifier.add(reader, .peer_hangup) or {
        // Gracefully handle unsupported feature
        eprintln('Note: peer_hangup not supported: ${err}')
        // Continue with just read events
    }

    // Your event loop
    for {
        events := notifier.wait(1 * time.second)
        for event in events {
            if event.kind.has(.read) {
                // Handle read
                data, _ := os.fd_read(event.fd, 1024)
                println('Read: ${data}')
            }
            if event.kind.has(.peer_hangup) {
                // This will only trigger on Linux
                println('Peer disconnected')
                break
            }
        }
    }
}
```

## Platform-Specific Code

You can also use conditional compilation for platform-specific features:

```v
import os.notify

fn setup_notifier(mut notifier notify.FdNotifier, fd int) ! {
    $if linux {
        // Use all available features on Linux
        notifier.add(fd, .read | .peer_hangup, .edge_trigger)!
    } $else $if macos {
        // Use only supported features on macOS
        notifier.add(fd, .read, .edge_trigger)!
    }
}
```

## Checking Platform Capabilities

For library code that needs to work across platforms, use error handling:

```v
fn add_with_hangup(mut notifier notify.FdNotifier, fd int) ! {
    // Try with hangup first
    notifier.add(fd, .read | .hangup) or {
        // If it fails, fall back to just read
        if err.msg().contains('hangup') {
            notifier.add(fd, .read)!
        } else {
            // Some other error, propagate it
            return err
        }
    }
}
```
