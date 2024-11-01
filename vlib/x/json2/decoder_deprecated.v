module json2

pub struct DecodeError {
	line    int
	column  int
	message string
}

// code returns the error code of DecodeError
pub fn (err DecodeError) code() int {
	return 3
}

// msg returns the message of the DecodeError
pub fn (err DecodeError) msg() string {
	if true {
		panic('this method is deprecated')
	}
	return ''
}

pub struct InvalidTokenError {
	DecodeError
	token    Token
	expected TokenKind
}

// code returns the error code of the InvalidTokenError
pub fn (err InvalidTokenError) code() int {
	return 2
}

// msg returns the message of the InvalidTokenError
pub fn (err InvalidTokenError) msg() string {
	if true {
		panic('this method is deprecated')
	}
	return ''
}

pub struct UnknownTokenError {
	DecodeError
	token Token
	kind  ValueKind = .unknown
}

// code returns the error code of the UnknownTokenError
pub fn (err UnknownTokenError) code() int {
	return 1
}

// msg returns the error message of the UnknownTokenError
pub fn (err UnknownTokenError) msg() string {
	if true {
		panic('this method is deprecated')
	}
	return ''
}

struct Parser {
pub mut:
	scanner      &Scanner = unsafe { nil }
	prev_tok     Token
	tok          Token
	next_tok     Token
	n_level      int
	convert_type bool = true
}

// Decodes a JSON string into an `Any` type. Returns an option.
@[deprecated: 'use `json.decode[json.Any](src string)` instead']
pub fn raw_decode(src string) !Any {
	return decode[Any](src)!
}

// Same with `raw_decode`, but skips the type conversion for certain types when decoding a certain value.
@[deprecated: 'use `json.decode[json.Any](src string)` instead']
pub fn fast_raw_decode(src string) !Any {
	return decode[Any](src)!
}

// decode - decodes provided JSON
pub fn (mut p Parser) decode() !Any {
	return error('This method is deprecated.')
}
