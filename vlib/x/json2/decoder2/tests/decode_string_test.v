import x.json2.decoder2 as json

// fn test_json_string_characters() {
// 	assert json.decode[string](r'"\/"').bytes() == [u8(`/`)]
// 	assert json.decode[string](r'"\\"').bytes() == [u8(`\\`)]
// 	assert json.decode[string](r'"\""').bytes() == [u8(`"`)]
// 	assert json.decode[string](r'"\n"').bytes() == [u8(`\n`)]
// 	assert json.decode[string](r'"\\n\\r"') == r'\n\r'
// 	assert json.decode[string](r'"\\n"') == '\\n'
// 	assert json.decode[string](r'"\\n\\r\\b"') == r'\n\r\b'
// 	assert json.decode[string](r'"\\\"\/"').bytes() == r'\"/'.bytes()

// 	assert json.decode[string](r'"\\n\\r\\b\\f\\t\\\\\\\"\\\/"') == r'\n\r\b\f\t\\\"\/'

// 	assert json.decode[string]('"\\n\\r\\b\\f\\t\\\\\\"\\/"') == r'"\n\r\b\f\t\\\"\/"'

// 	assert json.decode[string]('"fn main(){nprintln(\'Hello World! Helo \$a\')\\n}"') == "fn main(){nprintln('Hello World! Helo \$a')\n}"
// 	assert json.decode[string]('" And when \\"\'s are in the string, along with # \\""') == ' And when "\'s are in the string, along with # "'
// 	assert json.decode[string](r'"a \\\nb"') == 'a \\\nb'
// 	assert json.decode[string]('"Name\\tJosé\\nLocation\\tSF."') == 'Name\tJosé\nLocation\tSF.'
// }

// fn test_json_escape_low_chars() {
// 	assert json.decode[string](r'"\u001b"') == '\u001b'
// 	assert json.decode[string](r'"\u000f"') == '\u000f'
// 	assert json.decode[string](r'" "') == '\u0020'
// 	assert json.decode[string](r'"\u0000"') == '\u0000'
// }

fn test_json_string() {
	// assert json.decode[string](r'"te\u2714st"')! == 'te✔st'
	// assert json.decode[string]('te✔st')! == 'te✔st'
}

fn test_json_string_emoji() {
	assert json.decode[string](r'"🐈"')! == '🐈'
	assert json.decode[string](r'"💀"')! == '💀'
	assert json.decode[string](r'"🐈💀"')! == '🐈💀'
}

fn test_json_string_non_ascii() {
	// assert json.decode[string](r'"\u3072\u3089\u304c\u306a"')! == 'ひらがな'
	dump('ひ'.len)
	assert json.decode[string]('"a\\u3072b\\u3089c\\u304cd\\u306ae fgh"')! == 'aひbらcがdなe fgh'
	assert json.decode[string]('"\\u3072\\u3089\\u304c\\u306a"')! == 'ひらがな'
}

fn test_utf8_strings_are_not_modified() {
	assert json.decode[string]('"ü"')! == 'ü'
	assert json.decode[string]('"Schilddrüsenerkrankungen"')! == 'Schilddrüsenerkrankungen'
}
