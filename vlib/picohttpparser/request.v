module picohttpparser

const max_headers = 100

pub struct Header {
pub mut:
	name  string
	value string
}

pub struct Request {
mut:
	prev_len int
pub mut:
	method      string
	path        string
	headers     [max_headers]Header
	num_headers int
	body        string
}

// Pret contains the nr of bytes read, a negative number indicates an error
pub struct Pret {
pub mut:
	err string
	// -1 indicates a parse error and -2 means the request is parsed
	ret int
}

// parse_request parses a raw HTTP request and returns the number of bytes read.
// -1 indicates a parse error and -2 means the request is parsed
// The `method` and `path` fields are set

@[inline]
pub fn (mut r Request) parse_request_by_buffer(buffer []u8) !int {
	if buffer.len == 0 {
		return -2
	}
	unsafe {
		mut buf := &buffer[0]
		buf_end := buf + buffer.len

		mut method := &u8(0)
		mut method_len := int(0)
		mut path := &u8(0)
		mut path_len := int(0)
		mut minor_version := 0
		mut headers := [max_headers]Phr_header{}
		mut num_headers := int(0)
		pret := Pret{}

		buf = parse_request(buf, buf_end, &method, &method_len, &path, &path_len, &minor_version,
			&headers[0], &num_headers, max_headers, &pret.ret)

		if pret.ret == -1 {
			return error('parse error with ${num_headers} headers and ${minor_version} version and ${method} method and ${path}. code: ${pret.ret}')
		} else if pret.ret == -2 {
			// 'error parsing request: invalid character "13"'
			return error('incomplete request: invalid character')
		}

		r.method = tos(method, int(method_len))
		r.path = tos(path, int(path_len))
		r.num_headers = int(num_headers)
		for i in 0 .. r.num_headers {
			r.headers[i] = Header{
				name:  tos(headers[i].name, int(headers[i].name_len))
				value: tos(headers[i].value, int(headers[i].value_len))
			}
		}

		r.body = tos(buf, int(buf_end - buf))
	// r.body = unsafe { (&s.str[pret.ret]).vstring_literal_with_len(s.len - pret.ret) }

		return buffer.len
	}
}

@[inline]
pub fn (mut r Request) parse_request(s string) !int {
	unsafe {
		return r.parse_request_by_buffer(s.str.vbytes(s.len))
	}
}

// parse_request parses a raw HTTP request and returns the number of bytes read.
// -1 indicates a parse error and -2 means the request is parsed
@[inline; unsafe]
fn parse_request(buf &u8, buf_end &u8, method &&u8, method_len &int, path &&u8, path_len &int, minor_version &int, headers &Phr_header, num_headers &int, max_headers int, ret &int) &u8 {
	// skip first empty line (some clients add CRLF after POST content)
	if buf == buf_end {
		unsafe {
			*ret = -2
		}
		return unsafe { nil }
	}
	if *buf == `\r` {
		unsafe { buf++ }
		if buf == buf_end || *buf != `\n` {
			unsafe {
				*ret = -1
			}
			return unsafe { nil }
		}
		unsafe { buf++ }
	} else if *buf == `\n` {
		unsafe { buf++ }
	}

	// parse request line
	unsafe {
		buf = parse_token(buf, buf_end, method, method_len, ` `, ret)
	}
	if buf == unsafe { nil } {
		return unsafe { nil }
	}
	for *buf == u8(` `) {
		if buf == buf_end {
			unsafe {
				*ret = -2
			}
			return unsafe { nil }
		}
		buf++
	}
	// ADVANCE_TOKEN
	tok_start := buf
	ranges2 := c'\000 \177\177'
	found2 := 0
	unsafe {
		buf = findchar_fast(buf, buf_end, ranges2, 4, &found2)
	}
	if found2 != 0 {
		if buf == buf_end {
			unsafe {
				*ret = -2
			}
			return unsafe { nil }
		}
	}
	for {
		if *buf == u8(` `) {
			break
		} else if !is_printable_ascii(*buf) {
			if *buf < u8(` `) || *buf == 127 {
				unsafe {
					*ret = -1
				}
				return unsafe { nil }
			}
		}
		unsafe { buf++ }
		if buf == buf_end {
			unsafe {
				*ret = -2
			}
			return unsafe { nil }
		}
	}
	unsafe {
		*path = tok_start
	}
	unsafe {
		*path_len = buf - tok_start
	}
	for *buf == u8(` `) {
		if buf == buf_end {
			unsafe {
				*ret = -2
			}
			return unsafe { nil }
		}
		buf++
	}
	if *method_len == 0 || *path_len == 0 {
		unsafe {
			*ret = -1
		}
		return unsafe { nil }
	}
	unsafe {
		buf = parse_http_version(buf, buf_end, minor_version, ret)
	}
	if buf == unsafe { nil } {
		return unsafe { nil }
	}
	if *buf == `\r` {
		unsafe { buf++ }
		if buf == buf_end || *buf != `\n` {
			unsafe {
				*ret = -1
			}
			return unsafe { nil }
		}
		unsafe { buf++ }
	} else if *buf == `\n` {
		unsafe { buf++ }
	} else {
		unsafe {
			*ret = -1
		}
		return unsafe { nil }
	}

	return parse_headers(buf, buf_end, headers, num_headers, max_headers, ret)
}

// parse_request_path sets the `path` and `method` fields
@[inline]
pub fn (mut r Request) parse_request_path(s string) !int {
	mut buf := s.str
	buf_end := unsafe { s.str + s.len }

	mut pret := Pret{}
	r.phr_parse_request_path(buf, buf_end, &pret.ret)
	if pret.ret == -1 {
		return error(pret.err)
	}

	return pret.ret
}

// parse_request_path_pipeline can parse the `path` and `method` of HTTP/1.1 pipelines.
// Call it again to parse the next request
@[inline]
pub fn (mut r Request) parse_request_path_pipeline(s string) !int {
	mut buf := unsafe { s.str + r.prev_len }
	buf_end := unsafe { s.str + s.len }

	mut pret := Pret{}
	r.phr_parse_request_path_pipeline(buf, buf_end, &pret.ret)
	if pret.ret == -1 {
		return error(pret.err)
	}

	if pret.ret > 0 {
		r.prev_len = pret.ret
	}
	return pret.ret
}
