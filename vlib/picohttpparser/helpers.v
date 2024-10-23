module picohttpparser

type Size_t = u32
type Wchar_t = int
type Ushort = u16
type Uint = u32

// type U_int8_t = Uint8_t
// type U_int16_t = Uint16_t
type U_int32_t = u32
type U_int64_t = u64
type Register_t = int

const chunked_in_chunk_size = 0
const chunked_in_chunk_ext = 1
const chunked_in_chunk_data = 2
const chunked_in_chunk_crlf = 3
const chunked_in_trailers_line_head = 4
const chunked_in_trailers_line_middle = 5

struct Phr_chunked_decoder {
	bytes_left_in_chunk int
	consume_trailer     u8
	hex_count           u8
	state               u8
	total_read          u64
	total_overhead      u64
}

struct Phr_header {
pub mut:
	name      &u8 = unsafe { nil }
	name_len  int
	value     &u8 = unsafe { nil }
	value_len int
}

// Helpers

fn unlikely(x bool) bool {
	// __builtin_expect(x, 0)
	return x
}

@[unsafe]
fn check_eof(buf &u8, buf_end &u8, ret &int) ! {
	if buf == buf_end {
		*ret = -2
		return error('EOF reached')
	}
}

// fn expect_char_no_check(buf &u8, ch u8, ret &int) ! {
// 	if *buf++ != ch {
// 		*ret = -1
// 		return error('Expected character not found')
// 	}
// }

// fn expect_char(buf &u8, buf_end &u8, ch u8, ret &int) ! {
// 	check_eof(buf, buf_end, ret)?
// 	expect_char_no_check(buf, ch, ret)?
// }

// fn decode_hex(ch int) int {
// 	if `0` <= ch && ch <= `9` {
// 		return ch - `0`
// 	} else if `A` <= ch && ch <= `F` {
// 		return ch - `A` + 10
// 	} else if `a` <= ch && ch <= `f` {
// 		return ch - `a` + 0xa
// 	} else {
// 		return -1
// 	}
// }
