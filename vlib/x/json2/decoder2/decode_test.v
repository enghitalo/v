module decoder2

fn test_calculate_string_space_and_escapes() {
	// mut decoder := Decoder{
	// 	json: '""'
	// }
	// assert decoder.calculate_string_space_and_escapes()! == 0, []int{}

	// assert calculate_string_space_and_escapes('"abcd"')! == 4

	// assert calculate_string_space_and_escapes('"ç"')! == 2

	// assert calculate_string_space_and_escapes('"\u001b"')! == 1

	// assert calculate_string_space_and_escapes('"\\u001b"')! == 1

	// assert calculate_string_space_and_escapes('"✔"')! == 3

	// assert calculate_string_space_and_escapes('"\\u2714"')! == 3 // '✔'

	// assert calculate_string_space_and_escapes('"te\\u2714st"')! == 7

	// assert calculate_string_space_and_escapes('"ひ"')! == 3

	// assert calculate_string_space_and_escapes('"\\u3072"')! == 3

	// assert calculate_string_space_and_escapes('"ü"')! == 2

	// assert calculate_string_space_and_escapes('"🐈"')! == 4

	// assert calculate_string_space_and_escapes('"\\u0041"')! == 1 // 'A'
	// assert calculate_string_space_and_escapes('"\\u1F600"')! == 4 // '😀'
	// assert calculate_string_space_and_escapes('"\\\\"')! == 1 // '\'
	// assert calculate_string_space_and_escapes('"\\n"')! == 1 // '\n'
}

fn test_check_if_json_match() {
	// /* Test wrong string values */
	mut has_error := false

	check_if_json_match[string]('{"key": "value"}') or {
		assert err.str() == 'Expected string, but got object'
		has_error = true
	}
	assert has_error, 'Expected error'
	has_error = false

	check_if_json_match[map[string]string]('"value"') or {
		assert err.str() == 'Expected object, but got string_'
		has_error = true
	}
	assert has_error, 'Expected error'
	has_error = false

	check_if_json_match[[]int]('{"key": "value"}') or {
		assert err.str() == 'Expected array, but got object'
		has_error = true
	}
	assert has_error, 'Expected error'
	has_error = false

	check_if_json_match[string]('[1, 2, 3]') or {
		assert err.str() == 'Expected string, but got array'
		has_error = true
	}
	assert has_error, 'Expected error'
	has_error = false

	check_if_json_match[int]('{"key": "value"}') or {
		assert err.str() == 'Expected number, but got object'
		has_error = true
	}
	assert has_error, 'Expected error'
	has_error = false

	check_if_json_match[bool]('{"key": "value"}') or {
		assert err.str() == 'Expected boolean, but got object'
		has_error = true
	}
	assert has_error, 'Expected error'
	has_error = false

	// /* Right string values */
	check_if_json_match[string]('"value"') or { assert false }

	check_if_json_match[map[string]string]('{"key": "value"}') or { assert false }

	check_if_json_match[[]int]('[1, 2, 3]') or { assert false }

	check_if_json_match[string]('"string"') or { assert false }

	check_if_json_match[int]('123') or { assert false }

	check_if_json_match[bool]('true') or { assert false }

	check_if_json_match[bool]('false') or { assert false }

	// TODO: test null
}

fn test_check_json_format() {
	// primitives
	for variable in ['""', '"string"', '123', '0', 'true'] {
		mut checker := Decoder{
			checker_idx: 0
			json:        variable
		}

		checker.check_json_format(variable) or { assert false, err.str() }
		assert checker.checker_idx == checker.json.len - 1, 'Expected to reach the end of the json string ${checker.json}'
	}

	// simple objects
	for variable in ['{}', '{"key": null}', '{"key": "value"}', '{"key": 123}', '{"key": true}'] {
		mut checker := Decoder{
			checker_idx: 0
			json:        variable
		}

		checker.check_json_format(variable) or { assert false, err.str() }
		assert checker.checker_idx == checker.json.len - 1, 'Expected to reach the end of the json string ${checker.json}'
	}

	// Nested objects
	for variable in ['{"key": {"key": 123}}'] {
		mut checker := Decoder{
			checker_idx: 0
			json:        variable
		}

		checker.check_json_format(variable) or { assert false, err.str() }
		assert checker.checker_idx == checker.json.len - 1, 'Expected to reach the end of the json string ${checker.json}'
	}

	// simple arrays
	for variable in ['[]', '[1, 2, 3]', '["a", "b", "c"]', '[true, false]'] {
		mut checker := Decoder{
			checker_idx: 0
			json:        variable
		}

		checker.check_json_format(variable) or { assert false, err.str() }
		assert checker.checker_idx == checker.json.len - 1, 'Expected to reach the end of the json string ${checker.json}'
	}

	// Nested arrays
	for variable in ['[[1, 2, 3], [4, 5, 6]]'] {
		mut checker := Decoder{
			checker_idx: 0
			json:        variable
		}

		checker.check_json_format(variable) or { assert false, err.str() }
		// assert checker.checker_idx == checker.json.len - 1, 'Expected to reach the end of the json string ${checker.json}'
	}

	// Wrong jsons

	json_and_error_message := [
		{
			'json':  ']'
			'error': '\n]\n^ unknown value kind'
		},
		{
			'json':  '}'
			'error': '\n}\n^ unknown value kind'
		},
		{
			'json':  'truely'
			'error': '\ntruel\n    ^ invalid value. Unexpected character after boolean end'
		},
		{
			'json':  '0[1]' //
			'error': '\n0[\n ^ invalid number'
		},
		{
			'json':  '[1, 2, g3]'
			'error': '\n[1, 2, g\n       ^ unknown value kind'
		},
		{
			'json':  '[1, 2,, 3]'
			'error': '\n[1, 2,,\n      ^ unknown value kind'
		},
		{
			'json':  '{"key": 123'
			'error': '\n{"key": 123\n          ^ EOF error: braces are not closed'
		},
		{
			'json':  '{"key": 123,'
			'error': '\n{"key": 123,\n           ^ EOF error: braces are not closed'
		},
		{
			'json':  '{"key": 123, "key2": 456,}'
			'error': '\n{"key": 123, "key2": 456,}\n                         ^ Expecting object key'
		},
		{
			'json':  '[[1, 2, 3], [4, 5, 6],]'
			'error': '\n[[1, 2, 3], [4, 5, 6],]\n                      ^ Cannot use `,`, before `]`'
		},
	]

	for json_and_error in json_and_error_message {
		mut has_error := false
		mut checker := Decoder{
			checker_idx: 0
			json:        json_and_error['json']
		}

		checker.check_json_format(json_and_error['json']) or {
			assert err.str() == json_and_error['error']
			has_error = true
		}
		assert has_error, 'Expected error ${json_and_error['error']}'
	}
}

fn test_get_value_kind() {
	assert get_value_kind(`"`) == .string_
	assert get_value_kind(`t`) == .boolean
	assert get_value_kind(`f`) == .boolean
	assert get_value_kind(`{`) == .object
	assert get_value_kind(`[`) == .array
	assert get_value_kind(`0`) == .number
	assert get_value_kind(`-`) == .number
	assert get_value_kind(`n`) == .null
	assert get_value_kind(`x`) == .unknown
}

fn test_checker_values_info() {
	// Test for string value
	mut checker := Decoder{
		checker_idx: 0
		json:        '"value"'
	}
	checker.check_json_format(checker.json) or { assert false, err.str() }
	assert checker.values_info.len == 1
	assert checker.values_info[0].position == 0
	assert checker.values_info[0].length == 7
	assert checker.values_info[0].value_kind == .string_

	// Test for number value
	checker = Decoder{
		checker_idx: 0
		json:        '123'
	}
	checker.check_json_format(checker.json) or { assert false, err.str() }
	assert checker.values_info.len == 1
	assert checker.values_info[0].position == 0
	assert checker.values_info[0].length == 3
	assert checker.values_info[0].value_kind == .number

	// Test for boolean value
	checker = Decoder{
		checker_idx: 0
		json:        'true'
	}
	checker.check_json_format(checker.json) or { assert false, err.str() }
	assert checker.values_info.len == 1
	assert checker.values_info[0].position == 0
	assert checker.values_info[0].length == 4
	assert checker.values_info[0].value_kind == .boolean

	// Test for null value
	checker = Decoder{
		checker_idx: 0
		json:        'null'
	}
	checker.check_json_format(checker.json) or { assert false, err.str() }
	assert checker.values_info.len == 1
	assert checker.values_info[0].position == 0
	assert checker.values_info[0].length == 4
	assert checker.values_info[0].value_kind == .null

	// Test for object value
	checker = Decoder{
		checker_idx: 0
		json:        '{"key": "value"}'
	}
	checker.check_json_format(checker.json) or { assert false, err.str() }
	assert checker.values_info.len == 3
	assert checker.values_info[0].position == 0
	assert checker.values_info[0].length == 16
	assert checker.values_info[0].value_kind == .object
	assert checker.values_info[1].position == 1
	assert checker.values_info[1].length == 5
	assert checker.values_info[1].value_kind == .string_
	assert checker.values_info[2].position == 8
	assert checker.values_info[2].length == 7
	assert checker.values_info[2].value_kind == .string_

	// Test for nested object value
	checker = Decoder{
		checker_idx: 0
		// json: '0<-{1"key1": 9<-{10"key2": 18"value1"}}'
		json: '{"key1": {"key2": "value1"}'
	}
	checker.check_json_format(checker.json) or { assert false, err.str() }
	dump(checker.values_info)
	assert checker.values_info.len == 5
	assert checker.values_info[0].position == 0
	assert checker.values_info[0].length == 27
	assert checker.values_info[0].value_kind == .object
	assert checker.values_info[1].position == 1
	assert checker.values_info[1].length == 6
	assert checker.values_info[1].value_kind == .string_
	assert checker.values_info[2].position == 9
	assert checker.values_info[2].length == 18
	assert checker.values_info[2].value_kind == .object
	assert checker.values_info[3].position == 10
	assert checker.values_info[3].length == 6
	assert checker.values_info[3].value_kind == .string_
	assert checker.values_info[4].position == 18
	assert checker.values_info[4].length == 8

	// Test for array value
	checker = Decoder{
		checker_idx: 0
		json:        '[1, 22, 333]'
	}
	checker.check_json_format(checker.json) or { assert false, err.str() }
	assert checker.values_info.len == 4
	assert checker.values_info[0].position == 0
	assert checker.values_info[0].length == 12
	assert checker.values_info[0].value_kind == .array
	assert checker.values_info[1].position == 1
	assert checker.values_info[1].length == 1
	assert checker.values_info[1].value_kind == .number
	assert checker.values_info[2].position == 4
	assert checker.values_info[2].length == 2
	assert checker.values_info[2].value_kind == .number
	assert checker.values_info[3].position == 8
	assert checker.values_info[3].length == 3
	assert checker.values_info[3].value_kind == .number
}

fn test_string_non_ascii() {
	json_string := '"a\\u3072b\\u3089c\\u304cd\\u306a"'
	mut checker := Decoder{
		checker_idx: 0
		json:        json_string
	}

	checker.check_json_format(checker.json)!

	assert checker.values_info.len == 1

	mut decoder := Decoder{
		json:        json_string
		values_info: checker.values_info
	}

	space_required, escape_positions := decoder.calculate_string_space_and_escapes()!

	assert space_required == 16
	assert escape_positions.len == 4
	assert escape_positions[0] == 2
	assert escape_positions[1] == 9
	assert escape_positions[2] == 16
	assert escape_positions[3] == 23
}

fn test_generate_unicode_escape_sequence() {
	assert generate_unicode_escape_sequence([u8(`0`), `0`, `1`, `b`])! == '\u001b'.bytes()
	assert generate_unicode_escape_sequence([u8(`0`), `0`, `0`, `f`])! == '\u000f'.bytes()
	assert generate_unicode_escape_sequence([u8(`0`), `0`, `2`, `0`])! == '\u0020'.bytes()
	assert generate_unicode_escape_sequence([u8(`0`), `0`, `0`, `0`])! == '\u0000'.bytes()

	assert generate_unicode_escape_sequence([u8(`3`), `0`, `7`, `2`])! == 'ひ'.bytes()
	assert generate_unicode_escape_sequence([u8(`3`), `0`, `8`, `9`])! == 'ら'.bytes()
	assert generate_unicode_escape_sequence([u8(`3`), `0`, `4`, `c`])! == 'が'.bytes()
	assert generate_unicode_escape_sequence([u8(`3`), `0`, `6`, `a`])! == 'な'.bytes()

	assert generate_unicode_escape_sequence([u8(`0`), `0`, `4`, `1`])! == 'A'.bytes()

	assert generate_unicode_escape_sequence([u8(`0`), `0`, `2`, `f`])! == '/'.bytes()
	assert generate_unicode_escape_sequence([u8(`0`), `0`, `0`, `a`])! == '\n'.bytes()

	assert generate_unicode_escape_sequence([u8(`0`), `0`, `2`, `0`])! == ' '.bytes()

	assert generate_unicode_escape_sequence([u8(`2`), `7`, `1`, `4`])! == '✔'.bytes()
}

fn test_string_buffer_to_generic_unsigned_number() {
	// unsigned
	string_value := '123'
	bytes := unsafe { string_value.str.vbytes(3) }
	value := u32(0)
	unsafe { string_buffer_to_generic_number[u32](&value, bytes) }
	assert value == 123
}

fn test_string_buffer_to_generic_signed_number() {
	// signed
	string_value := '-123'
	bytes := unsafe { string_value.str.vbytes(4) }
	value := int(0)
	unsafe { string_buffer_to_generic_number[int](&value, bytes) }
	assert value == -123
}

fn test_string_buffer_to_generic_float_number() {
	// float
	string_value := '123.456'
	bytes := unsafe { string_value.str.vbytes(7) }
	value := f32(0)
	unsafe { string_buffer_to_generic_number[f32](&value, bytes) }
	assert value == 123.456
}
