module main

import x.json2 as json
import x.json2.decoder2

struct MyStruct {
	name   string // should fail
	age    ?int
	active bool
}

fn test_main() {
	mut errors := 0
	decoder2.decode[MyStruct]('{ "name": 1}') or {
		errors++
		assert err.msg() == "type mismatch for field 'name', expecting `string` type, got: 1"
	}
	decoder2.decode[MyStruct]('{ "name": "John Doe", "age": ""}') or {
		errors++
		assert err.msg() == 'type mismatch for field \'age\', expecting `?int` type, got: ""'
	}
	decoder2.decode[MyStruct]('{ "name": "John Doe", "age": 1, "active": ""}') or {
		errors++
		assert err.msg() == 'type mismatch for field \'active\', expecting `bool` type, got: ""'
	}
	res := decoder2.decode[MyStruct]('{ "name": "John Doe", "age": "1"}') or { panic(err) }
	assert errors == 3
}
