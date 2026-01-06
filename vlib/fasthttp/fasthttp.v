// Copyright (c) 2019-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module fasthttp

import runtime
import net
import os.notify
import time

#include <fcntl.h>
#include <errno.h>

$if !windows {
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <netinet/tcp.h>
}

const max_thread_pool_size = runtime.nr_cpus()
const max_connection_size = 65536 // Max events per epoll_wait

const tiny_bad_request_response = 'HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'.bytes()
const status_444_response = 'HTTP/1.1 444 No Response\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'.bytes()
const status_413_response = 'HTTP/1.1 413 Payload Too Large\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'.bytes()

fn C.socket(domain net.AddrFamily, typ net.SocketType, protocol int) int

fn C.bind(sockfd int, addr &net.Addr, addrlen u32) int

fn C.send(__fd int, __buf voidptr, __n usize, __flags int) int

fn C.recv(__fd int, __buf voidptr, __n usize, __flags int) int

fn C.setsockopt(__fd int, __level int, __optname int, __optval voidptr, __optlen u32) int

fn C.listen(__fd int, __n int) int

fn C.perror(s &u8)

fn C.close(fd int) int

fn C.htons(__hostshort u16) u16

fn C.fcntl(fd int, cmd int, arg int) int

pub struct Slice {
pub:
	start int
	len   int
}

// HttpRequest represents an HTTP request.
// TODO make fields immutable
pub struct HttpRequest {
pub mut:
	buffer         []u8 // A V slice of the read buffer for convenience
	method         Slice
	path           Slice
	version        Slice
	header_fields  Slice
	body           Slice
	client_conn_fd int
	user_data      voidptr // User-defined context data
}

// ServerConfig bundles the parameters needed to start a fasthttp server.
pub struct ServerConfig {
pub:
	port                    int = 3000
	max_request_buffer_size int = 8192
	handler                 fn (HttpRequest) ![]u8 @[required]
	user_data               voidptr
}

struct Server {
pub:
	port                    int = 3000
	max_request_buffer_size int = 8192
	user_data               voidptr
mut:
	listen_fds      []int    = []int{len: max_thread_pool_size, cap: max_thread_pool_size}
	threads         []thread = []thread{len: max_thread_pool_size, cap: max_thread_pool_size}
	request_handler fn (HttpRequest) ![]u8 @[required]
}

// new_server creates and initializes a new Server instance.
pub fn new_server(config ServerConfig) !&Server {
	if config.max_request_buffer_size <= 0 {
		return error('max_request_buffer_size must be greater than 0')
	}
	mut server := &Server{
		port:                    config.port
		max_request_buffer_size: config.max_request_buffer_size
		user_data:               config.user_data
		request_handler:         config.handler
	}
	unsafe {
		server.listen_fds.flags.set(.noslices | .noshrink | .nogrow)
		server.threads.flags.set(.noslices | .noshrink | .nogrow)
	}
	return server
}

fn set_blocking(fd int, blocking bool) {
	flags := C.fcntl(fd, C.F_GETFL, 0)
	if flags == -1 {
		// TODO: better error handling
		eprintln(@LOCATION)
		return
	}
	if blocking {
		// This removes the O_NONBLOCK flag from flags and set it.
		C.fcntl(fd, C.F_SETFL, flags & ~C.O_NONBLOCK)
	} else {
		// This adds the O_NONBLOCK flag from flags and set it.
		C.fcntl(fd, C.F_SETFL, flags | C.O_NONBLOCK)
	}
}

fn close_socket(fd int) bool {
	ret := C.close(fd)
	if ret == -1 {
		if C.errno == C.EINTR {
			// Interrupted by signal, retry is safe
			return close_socket(fd)
		}
		eprintln('ERROR: close(fd=${fd}) failed with errno=${C.errno}')
		return false
	}
	return true
}

fn create_server_socket(port int) int {
	// Create a socket with non-blocking mode
	server_fd := C.socket(net.AddrFamily.ip, net.SocketType.tcp, 0)
	if server_fd < 0 {
		eprintln(@LOCATION)
		C.perror(c'Socket creation failed')
		return -1
	}

	set_blocking(server_fd, false)

	// Enable SO_REUSEADDR and SO_REUSEPORT
	opt := 1
	if C.setsockopt(server_fd, C.SOL_SOCKET, C.SO_REUSEADDR, &opt, sizeof(opt)) < 0 {
		eprintln(@LOCATION)
		C.perror(c'setsockopt SO_REUSEADDR failed')
		close_socket(server_fd)
		return -1
	}
	if C.setsockopt(server_fd, C.SOL_SOCKET, C.SO_REUSEPORT, &opt, sizeof(opt)) < 0 {
		eprintln(@LOCATION)
		C.perror(c'setsockopt SO_REUSEPORT failed')
		close_socket(server_fd)
		return -1
	}

	addr := net.new_ip(u16(port), [u8(0), 0, 0, 0]!)
	alen := addr.len()
	if C.bind(server_fd, voidptr(&addr), alen) < 0 {
		eprintln(@LOCATION)
		C.perror(c'Bind failed')
		close_socket(server_fd)
		return -1
	}
	if C.listen(server_fd, max_connection_size) < 0 {
		eprintln(@LOCATION)
		C.perror(c'Listen failed')
		close_socket(server_fd)
		return -1
	}
	return server_fd
}

fn handle_accept_loop(mut notifier notify.FdNotifier, listen_fd int) {
	for {
		client_fd := C.accept4(listen_fd, C.NULL, C.NULL, C.SOCK_NONBLOCK)
		if client_fd < 0 {
			if C.errno == C.EAGAIN || C.errno == C.EWOULDBLOCK {
				break // No more incoming connections; exit loop.
			}
			eprintln(@LOCATION)
			C.perror(c'Accept failed')
			break
		}
		// Enable TCP_NODELAY for lower latency
		opt := 1
		C.setsockopt(client_fd, C.IPPROTO_TCP, C.TCP_NODELAY, &opt, sizeof(opt))
		// Register client socket with notifier
		notifier.add(client_fd, .read, .edge_trigger) or {
			eprintln('notifier.add failed: ${err}')
			close_socket(client_fd)
		}
	}
}

fn handle_client_closure(mut notifier notify.FdNotifier, client_fd int) {
	// Never close the listening socket here
	if client_fd == 0 {
		return
	}
	if client_fd <= 0 {
		eprintln('ERROR: Invalid FD=${client_fd} for closure')
		return
	}
	notifier.remove(client_fd) or {}
	close_socket(client_fd)
}

fn process_events(mut server Server, listen_fd int) {
	mut notifier := notify.new() or {
		eprintln('Failed to create notifier: ${err}')
		return
	}
	defer {
		notifier.close() or {}
	}
	notifier.add(listen_fd, .read, .edge_trigger) or {
		eprintln('Failed to add listen fd to notifier: ${err}')
		return
	}
	mut request_buffer := []u8{len: server.max_request_buffer_size, cap: server.max_request_buffer_size}
	unsafe {
		request_buffer.flags.set(.noslices | .nogrow | .noshrink)
	}
	for {
		for event in notifier.wait(time.infinite) {
			if event.fd == listen_fd {
				handle_accept_loop(mut notifier, listen_fd)
				continue
			}
			if event.kind.has(.error) || event.kind.has(.hangup) {
				client_fd := event.fd
				if client_fd == listen_fd {
					eprintln('ERROR: listen fd had HUP/ERR')
					continue
				}
				if client_fd > 0 {
					C.send(client_fd, status_444_response.data, status_444_response.len,
						C.MSG_NOSIGNAL)
					handle_client_closure(mut notifier, client_fd)
				} else {
					eprintln('ERROR: Invalid FD from notifier: ${client_fd}')
				}
				continue
			}
			if event.kind.has(.read) {
				client_fd := event.fd
				bytes_read := C.recv(client_fd, unsafe { &request_buffer[0] }, server.max_request_buffer_size - 1,
					0)
				if bytes_read > 0 {
					// Check if request exceeds buffer size
					if bytes_read >= server.max_request_buffer_size - 1 {
						C.send(client_fd, status_413_response.data, status_413_response.len,
							C.MSG_NOSIGNAL)
						handle_client_closure(mut notifier, client_fd)
						continue
					}
					mut readed_request_buffer := []u8{cap: bytes_read}
					unsafe {
						readed_request_buffer.push_many(&request_buffer[0], bytes_read)
					}
					mut decoded_http_request := decode_http_request(readed_request_buffer) or {
						eprintln('Error decoding request ${err}')
						C.send(client_fd, tiny_bad_request_response.data, tiny_bad_request_response.len,
							C.MSG_NOSIGNAL)
						handle_client_closure(mut notifier, client_fd)
						continue
					}
					decoded_http_request.client_conn_fd = client_fd
					decoded_http_request.user_data = server.user_data
					response_buffer := server.request_handler(decoded_http_request) or {
						eprintln('Error handling request ${err}')
						C.send(client_fd, tiny_bad_request_response.data, tiny_bad_request_response.len,
							C.MSG_NOSIGNAL)
						handle_client_closure(mut notifier, client_fd)
						continue
					}
					// Send response
					sent := C.send(client_fd, response_buffer.data, response_buffer.len,
						C.MSG_NOSIGNAL | C.MSG_DONTWAIT)
					if sent < 0 && C.errno != C.EAGAIN && C.errno != C.EWOULDBLOCK {
						eprintln('ERROR: send() failed with errno=${C.errno}')
						handle_client_closure(mut notifier, client_fd)
						continue
					}
					// Leave the connection open; closure is driven by client FIN or errors
				} else if bytes_read == 0 {
					// Normal client closure (FIN received)
					handle_client_closure(mut notifier, client_fd)
				} else if bytes_read < 0 && C.errno != C.EAGAIN && C.errno != C.EWOULDBLOCK {
					// Unexpected recv error - send 444 No Response
					C.send(client_fd, status_444_response.data, status_444_response.len,
						C.MSG_NOSIGNAL)
					handle_client_closure(mut notifier, client_fd)
				}
			}
		}
	}
}

// run starts the server and begins listening for incoming connections.
pub fn (mut server Server) run() ! {
	$if windows {
		eprintln('Windows is not supported yet')
		return
	}
	for i := 0; i < max_thread_pool_size; i++ {
		server.listen_fds[i] = create_server_socket(server.port)
		if server.listen_fds[i] < 0 {
			return
		}
		server.threads[i] = spawn process_events(mut server, server.listen_fds[i])
	}

	println('listening on http://localhost:${server.port}/')
	// Main thread waits for workers; accepts are handled in worker epoll loops
	for i in 0 .. max_thread_pool_size {
		server.threads[i].wait()
	}
}
