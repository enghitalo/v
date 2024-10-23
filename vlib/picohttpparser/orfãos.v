module picohttpparser

// fn phr_parse_response(buf_start &u8, len int, minor_version &int, status &int, msg &&u8, msg_len &int, headers &Phr_header, num_headers &int, last_len int) int {
// 	unsafe { buf := buf_start }
// 	buf_end := buf + len
// 	max_headers := *num_headers
// 	r := 0
// 	unsafe { *minor_version = -1 }
// 	*status =  unsafe { nil }
// 	 *msg = unsafe { nil }
// 	*msg_len =  unsafe { nil }
// 	*num_headers =  unsafe { nil }
// 	if last_len != 0 && is_complete(buf, buf_end, last_len, &r) == unsafe { nil } {
// 		return r
// 	}
// 	buf = parse_response(buf, buf_end, minor_version, status, msg, msg_len, headers, num_headers,
// 		max_headers, &r)
// 	if buf == unsafe { nil } {
// 		return r
// 	}
// 	return int(buf - buf_start)
// }

// fn phr_parse_headers(buf_start &u8, len int, headers &Phr_header, num_headers &int, last_len int) int {
// 	unsafe { buf := buf_start }
// 	buf_end := buf + len
// 	max_headers := *num_headers
// 	r := 0
// 	*num_headers =  unsafe { nil }
// 	if last_len != 0 && is_complete(buf, buf_end, last_len, &r) == unsafe { nil } {
// 		return r
// 	}
// 	buf = parse_headers(buf, buf_end, headers, num_headers, max_headers, &r)
// 	if buf == unsafe { nil } {
// 		return r
// 	}
// 	return int(buf - buf_start)
// }

// fn findchar_fast(buf &u8, buf_end &u8, ranges &u8, ranges_size int, mut found &int) &u8 {
// 	found = unsafe { nil }
// 	// SSE4.2 specific code omitted for simplicity
// 	return unsafe { buf }
// }

// fn phr_decode_chunked(decoder &Phr_chunked_decoder, buf &u8, _bufsz &int) Ssize_t {
// 	mut dst := 0
// 	mut src := 0
// 	mut bufsz := *_bufsz
// 	mut ret := -2
// 	decoder.total_read += bufsz

// 	for {
// 		match decoder.state {
// 			.chunked_in_chunk_size {
// 				for {
// 					if src == bufsz {
// 						goto exit
// 					}
// 					v := decode_hex(buf[src])
// 					if v == -1 {
// 						if decoder.hex_count == 0 {
// 							*ret = -1
// 							goto exit
// 						}
// 						match buf[src] {
// 							` `, `\t`, `;`, `\n`, `\r` {
// 								goto exit
// 							}
// 							else {
// 								*ret = -1
// 								goto exit
// 							}
// 						}
// 					}
// 					if decoder.hex_count == sizeof(int) * 2 {
// 						*ret = -1
// 						goto exit
// 					}
// 					decoder.bytes_left_in_chunk = decoder.bytes_left_in_chunk * 16 + v
// 					decoder.hex_count++
// 					src++
// 				}
// 				decoder.hex_count = 0
// 				decoder.state = .chunked_in_chunk_ext
// 			}
// 			.chunked_in_chunk_ext {
// 				for {
// 					if src == bufsz {
// 						goto exit
// 					}
// 					if buf[src] == `\n` {
// 						break
// 					}
// 					src++
// 				}
// 				src++
// 				if decoder.bytes_left_in_chunk == 0 {
// 					if decoder.consume_trailer {
// 						decoder.state = .chunked_in_trailers_line_head
// 					} else {
// 						goto complete
// 					}
// 				}
// 				decoder.state = .chunked_in_chunk_data
// 			}
// 			.chunked_in_chunk_data {
// 				avail := bufsz - src
// 				if avail < decoder.bytes_left_in_chunk {
// 					if dst != src {
// 						C.memmove(buf + dst, buf + src, avail)
// 					}
// 					src += avail
// 					dst += avail
// 					decoder.bytes_left_in_chunk -= avail
// 					goto exit
// 				}
// 				if dst != src {
// 					C.memmove(buf + dst, buf + src, decoder.bytes_left_in_chunk)
// 				}
// 				src += decoder.bytes_left_in_chunk
// 				dst += decoder.bytes_left_in_chunk
// 				decoder.bytes_left_in_chunk = 0
// 				decoder.state = .chunked_in_chunk_crlf
// 			}
// 			.chunked_in_chunk_crlf {
// 				for {
// 					if src == bufsz {
// 						goto exit
// 					}
// 					if buf[src] != `\r` {
// 						break
// 					}
// 					src++
// 				}
// 				if buf[src] != `\n` {
// 					*ret = -1
// 					goto exit
// 				}
// 				src++
// 				decoder.state = .chunked_in_chunk_size
// 			}
// 			.chunked_in_trailers_line_head {
// 				for {
// 					if src == bufsz {
// 						goto exit
// 					}
// 					if buf[src] != `\r` {
// 						break
// 					}
// 					src++
// 				}
// 				if buf[src++] == `\n` {
// 					goto complete
// 				}
// 				decoder.state = .chunked_in_trailers_line_middle
// 			}
// 			.chunked_in_trailers_line_middle {
// 				for {
// 					if src == bufsz {
// 						goto exit
// 					}
// 					if buf[src] == `\n` {
// 						break
// 					}
// 					src++
// 				}
// 				src++
// 				decoder.state = .chunked_in_trailers_line_head
// 			}
// 			else {
// 				panic('decoder is corrupt')
// 			}
// 		}
// 	}

// 	complete:
// 	ret = bufsz - src

// 	exit:
// 	if dst != src {
// 		C.memmove(buf + dst, buf + src, bufsz - src)
// 	}
// 	unsafe { *_bufsz = dst }
// 	if ret == -2 {
// 		decoder.total_overhead += bufsz - dst
// 		if decoder.total_overhead >= 100 * 1024
// 			&& decoder.total_read - decoder.total_overhead < decoder.total_read / 4 {
// 			*ret = -1
// 		}
// 	}
// 	return ret
// }

// fn phr_decode_chunked_is_in_data(decoder &Phr_chunked_decoder) int {
// 	return decoder.state == .chunked_in_chunk_data
// }

fn findchar_fast(buf &u8, buf_end &u8, ranges &u8, ranges_size int, found &int) &u8 {
	unsafe {
		// suppress unused parameter warning
		free(buf_end)
		free(ranges)
		free(ranges_size)
	}
	return unsafe { buf }
}

@[unsafe]
fn get_token_to_eol(buf &u8, buf_end &u8, token &&u8, token_len &int, ret &int) &u8 {
	token_start := buf
	for buf_end - buf >= 8 {
		for {
			if !is_printable_ascii(*buf) {
				goto NonPrintable
			}
			buf++
			if buf == buf_end {
				break
			}
		}
		continue
		NonPrintable:
		if (*buf < ` ` && *buf != `\t`) || *buf == 127 {
			goto FOUND_CTL
		}
		buf++
	}
	for buf != buf_end {
		if !is_printable_ascii(*buf) {
			if (*buf < ` ` && *buf != `\t`) || *buf == 127 {
				goto FOUND_CTL
			}
		}
		buf++
	}
	FOUND_CTL:
	if *buf == `\r` {
		buf++
		if *buf++ != `\n` {
			unsafe {
				*ret = -1
			}
			return unsafe { nil }
		}
		unsafe {
			*token_len = buf - 2 - token_start
		}
	} else if *buf == `\n` {
		unsafe {
			*token_len = buf - token_start
		}
		buf++
	} else {
		unsafe {
			*ret = -1
		}
		return unsafe { nil }
	}
	unsafe {
		*token = token_start
	}
	return unsafe { buf }
}

@[unsafe]
fn parse_token(buf &u8, buf_end &u8, token &&u8, token_len &int, next_char u8, ret &int) &u8 {
	ranges := c'\000 ""(),,//:@[]{\377'
	buf_start := buf
	found := 0
	buf = findchar_fast(buf, buf_end, ranges, sizeof(ranges) - 1, &found)

	if found != 0 {
		if buf == buf_end {
			unsafe {
				*ret = -2
			}
			return unsafe { nil }
		}
	}

	for {
		if *buf == next_char {
			break
		} else if token_char_map[*buf] == 0 {
			unsafe {
				*ret = -1
			}
			return unsafe { nil }
		}
		buf++
		if buf == buf_end {
			unsafe {
				*ret = -2
			}
			return unsafe { nil }
		}
	}
	unsafe {
		*token = buf_start
	}
	unsafe {
		*token_len = buf - buf_start
	}
	return unsafe { buf }
}

// fn parse_response(buf &u8, buf_end &u8, minor_version &int, status &int, msg &&u8, msg_len &int, headers &Phr_header, num_headers &int, max_headers int, ret &int) &u8 {
// 	buf = parse_http_version(buf, buf_end, minor_version,  ret)
// 	if buf == unsafe { nil } {
// 		return unsafe { nil }
// 	}
// 	if *buf != ` ` {
// 		unsafe { *ret = -1 }
// 		return unsafe { nil }
// 	}
// 	for ; *buf == ` `; buf++ {
// 		if buf == buf_end {
// 			unsafe { *ret = -2 }
// 			return unsafe { nil }
// 		}
// 	}
// 	if buf_end - buf < 4 {
// 		unsafe { *ret = -2 }
// 		return unsafe { nil }
// 	}
// 	res := 0
// 	if *buf < `0` || `9` < *buf {
// 		buf++
// 		unsafe { *ret = -1 }
// 		return unsafe { nil }
// 	}
// 	res = 100 * (*buf++ - `0`)
// 	unsafe { *status = res }
// 	if *buf < `0` || `9` < *buf {
// 		buf++
// 		unsafe { *ret = -1 }
// 		return unsafe { nil }
// 	}
// 	res = 10 * (*buf++ - `0`)
// 	*status += res
// 	if *buf < `0` || `9` < *buf {
// 		buf++
// 		unsafe { *ret = -1 }
// 		return unsafe { nil }
// 	}
// 	res = 1 * (*buf++ - `0`)
// 	*status += res
// 	buf = get_token_to_eol(buf, buf_end, msg, msg_len,  ret)
// 	if buf == unsafe { nil } {
// 		return unsafe { nil }
// 	}
// 	if *msg_len == 0 {
// 	} else if **msg == ` ` {
// 		for ; **msg == ` `; {
// 			*msg++
// 			*msg_len--
// 		}
// 	} else {
// 		unsafe { *ret = -1 }
// 		return unsafe { nil }
// 	}
// 	return unsafe { parse_headers(buf, buf_end, headers, num_headers, max_headers,  ret) }
// }
