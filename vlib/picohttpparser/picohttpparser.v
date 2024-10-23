module picohttpparser

// NOTE: picohttpparser is designed for speed. Please do some benchmarks when
// you change something in this file

// token_char_map contains all allowed characters in HTTP headers
const token_char_map = '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0' +
	'\0\1\0\1\1\1\1\1\0\0\1\1\0\1\1\0\1\1\1\1\1\1\1\1\1\1\0\0\0\0\0\0' +
	'\0\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\0\0\0\1\1' +
	'\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\1\0\1\0\1\0' +
	'\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0' +
	'\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0' +
	'\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0' +
	'\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'

const http_version = 'HTTP/1.'

fn (mut r Request) phr_parse_request_path(buf_start &u8, buf_end &u8, ret &int) {
	unsafe {
		buf := buf_start
		for buf != buf_end && *buf != ` ` {
			buf++
		}
		if buf == buf_end {
			*ret = -1
			return
		}
		r.path = tos(buf_start, buf - buf_start)
	}
}

fn (mut r Request) phr_parse_request_path_pipeline(buf_start &u8, buf_end &u8, ret &int) {
	unsafe {
		buf := buf_start
		for buf != buf_end && *buf != `|` {
			buf++
		}
		if buf == buf_end {
			*ret = -1
			return
		}
		r.path = tos(buf_start, buf - buf_start)
	}
}

// fn (mut r Request) phr_parse_request(buf_start &u8, buf_end &u8, ret &int) &u8
@[direct_array_access; unsafe]
fn phr_parse_request(buf_start &u8, len int, method &&u8, method_len &int, path &&u8, path_len &int, minor_version &int, headers &Phr_header, num_headers &int, last_len int, ret &int) int {
	buf := buf_start
	buf_end := buf_start + len

	// max_headers := *num_headers
	*method = unsafe { nil }
	*method_len = unsafe { nil }
	*path = unsafe { nil }
	*path_len = unsafe { nil }
	unsafe {
		*minor_version = -1
	}
	*num_headers = unsafe { nil }
	if last_len != 0 && is_complete(buf, buf_end, last_len, ret) == unsafe { nil } {
		return *ret
	}
	buf = parse_request(buf, buf_end, method, method_len, path, path_len, minor_version,
		headers, num_headers, max_headers, ret)
	if buf == unsafe { nil } {
		return *ret
	}
	return int(buf - buf_start)
}

// fn (mut r Request) parse_headers(buf_start &u8, buf_end &u8, ret &int) &u8
@[direct_array_access; unsafe]
fn parse_headers(buf_start &u8, buf_end &u8, headers &Phr_header, num_headers &int, max_headers int, ret &int) &u8 {
	mut buf := buf_start
	for {
		// CHECK_EOF
		if buf == buf_end {
			*ret = -2
			return unsafe { nil }
		}
		if *buf == `\r` {
			buf++
			if buf == buf_end || *buf != `\n` {
				*ret = -1
				return unsafe { nil }
			}
			buf++
			break
		} else if *buf == `\n` {
			buf++
			break
		}
		if *num_headers == max_headers {
			*ret = -1
			return unsafe { nil }
		}
		if !(*num_headers != 0 && (*buf == ` ` || *buf == `\t`)) {
			buf = parse_token(buf, buf_end, &headers[*num_headers].name, &headers[*num_headers].name_len,
				`:`, ret)
			if buf == unsafe { nil } {
				return unsafe { nil }
			}
			if headers[*num_headers].name_len == 0 {
				*ret = -1
				return unsafe { nil }
			}
			buf++
			for {
				if buf == buf_end {
					*ret = -2
					return unsafe { nil }
				}
				if !(*buf == ` ` || *buf == `\t`) {
					break
				}
				buf++
			}
		} else {
			headers[*num_headers].name = unsafe { nil }
			headers[*num_headers].name_len = 0
		}
		mut value := &u8(0)
		mut value_len := 0
		buf = get_token_to_eol(buf, buf_end, &value, &value_len, ret)
		if buf == unsafe { nil } {
			return unsafe { nil }
		}
		mut value_end := value + value_len
		for value_end != value {
			if !(*(value_end - 1) == ` ` || *(value_end - 1) == `\t`) {
				break
			}
			value_end--
		}

		headers[*num_headers].value = value
		headers[*num_headers].value_len = value_end - value

		*num_headers = *num_headers + 1
	}

	return buf
}

// is_complete checks if an http request is done
// fn is_complete(buf_start &u8, buf_end &u8, last_len int, ret &int) &u8

fn is_complete(buf_start &u8, buf_end &u8, last_len int, ret &int) &u8 {
	unsafe {
		ret_cnt := 0
		buf_start = if last_len < 3 { buf_start } else { buf_start + last_len - 3 }
		for {
			if buf_start == buf_end {
				*ret = -2
				return nil
			}
			if *buf_start == `\r` {
				buf_start++
				if *buf_start++ != `\n` {
					*ret = -1
					return nil
				}
				ret_cnt++
			} else if *buf_start == `\n` {
				buf_start++
				ret_cnt++
			} else {
				buf_start++
				ret_cnt = 0
			}
			if ret_cnt == 2 {
				return buf_start
			}
		}
		*ret = -2
		return nil
	}
}

// fn parse_http_version(buf_start &u8, buf_end &u8, ret &int) int
@[unsafe]
fn parse_http_version(buf_start &u8, buf_end &u8, minor_version &int, ret &int) &u8 {
	if buf_end - buf_start < 9 {
		*ret = -2
		return unsafe { nil }
	}

	for i := 0; i < http_version.len; i++ {
		if *buf_start++ != http_version[i] {
			*ret = -1
			return unsafe { nil }
		}
	}

	if *buf_start < `0` || `9` < *buf_start {
		unsafe { buf_start++ }
		*ret = -1
		return unsafe { nil }
	}
	unsafe {
		*minor_version = 1 * (*buf_start++ - u8(`0`))
	}
	return buf_start
}

// fn advance_token(tok_start &u8, tok_end &u8, ret &int) string
@[direct_array_access; inline; unsafe]
fn advance_token(tok &&u8, toklen &int, buf &u8, buf_end &u8, ret &int) &u8 {
	tok_start := buf
	ranges2 := [u8(0x00), 0x20, 0x7f, 0x7f]
	mut found2 := 0
	buf = findchar_fast(buf, buf_end, ranges2.data, ranges2.len, &found2)

	if found2 == 0 {
		if buf == buf_end {
			*ret = -2
			return unsafe { nil }
		}
	}
	for {
		if *buf == ` ` {
			break
		} else if !is_printable_ascii(*buf) {
			if *buf < ` ` || *buf == 127 {
				*ret = -1

				// return 'error parsing request: invalid character "${*tok_start}"'
				return unsafe { nil }
			}
		}
		buf++
		if buf == buf_end {
			*ret = -2
			return unsafe { nil }
		}
	}
	unsafe {
		*tok = tok_start
	}
	unsafe {
		*toklen = buf - tok_start
	}
	return buf
}

@[inline]
fn is_printable_ascii(c u8) bool {
	return c - 0x20 < 0x5f
}
