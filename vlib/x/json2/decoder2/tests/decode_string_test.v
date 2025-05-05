import x.json2.decoder2

fn test_json_escape_low_chars() {
	assert decoder2.decode[string](r'"\u001b"')! == '\u001b'
	assert decoder2.decode[string](r'"\u000f"')! == '\u000f'
	assert decoder2.decode[string](r'" "')! == '\u0020'
	assert decoder2.decode[string](r'"\u0000"')! == '\u0000'
}

fn test_json_string() {
	assert decoder2.decode[string](r'"te\u2714st"')! == 'te✔st'
	assert decoder2.decode[string](r'"te✔st"')! == 'te✔st'
	assert decoder2.decode[string]('""')! == ''
}

fn test_json_string_emoji() {
	assert decoder2.decode[string](r'"🐈"')! == '🐈'
	assert decoder2.decode[string](r'"💀"')! == '💀'
	assert decoder2.decode[string](r'"🐈💀"')! == '🐈💀'
}

fn test_json_string_non_ascii() {
	assert decoder2.decode[string](r'"\u3072\u3089\u304c\u306a"')! == 'ひらがな'
	assert decoder2.decode[string]('"a\\u3072b\\u3089c\\u304cd\\u306ae fgh"')! == 'aひbらcがdなe fgh'
	assert decoder2.decode[string]('"\\u3072\\u3089\\u304c\\u306a"')! == 'ひらがな'
}

fn test_utf8_strings_are_not_modified() {
	assert decoder2.decode[string]('"ü"')! == 'ü'
	assert decoder2.decode[string]('"Schilddrüsenerkrankungen"')! == 'Schilddrüsenerkrankungen'
}

fn test_json_string_invalid_escapes() {
	mut has_error := false

	decoder2.decode[string](r'"\x"') or {
		assert err.msg() == '\n"\\\n ^ unknown escape sequence'
		has_error = true
	} // Invalid escape

	assert has_error, 'Expected error'
	has_error = false

	decoder2.decode[string](r'"\u123"') or {
		assert err.msg() == '\n"\\\n ^ short unicode escape sequence \\u123"'
		has_error = true
	} // Incomplete Unicode

	assert has_error, 'Expected error'
}

fn test_json_string_whitespace() {
	// Test strings with whitespace
	assert decoder2.decode[string]('"   "')! == '   '
	assert decoder2.decode[string]('"\t\n\r"')! == '\t\n\r'
}
