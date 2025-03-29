import x.json2 as json
import x.json2.decoder2

struct TestOptionalRawString {
	id   int
	data ?string @[raw]
}

fn test_raw_opt() {
	test := TestOptionalRawString{
		id:   1
		data: 't
e
s
t'
	}
	encoded := json.encode(test)
	assert decoder2.decode[TestOptionalRawString](encoded)!.data? == r'"t\ne\ns\nt"'
}

fn test_raw_none() {
	test := TestOptionalRawString{
		id:   1
		data: none
	}
	encoded := json.encode(test)
	r := decoder2.decode[TestOptionalRawString](encoded)!.data
	assert r == none
}

fn test_raw_empty_string() {
	test := TestOptionalRawString{
		id:   1
		data: ''
	}
	encoded := json.encode(test)
	r := decoder2.decode[TestOptionalRawString](encoded)!.data or { 'z' }
	assert r == '""'
}
