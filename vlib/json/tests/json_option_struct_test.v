import x.json2 as json
import x.json2.decoder2

pub struct SomeStruct {
pub mut:
	test ?string
}

pub struct MyStruct {
pub mut:
	result ?SomeStruct
	id     string
}

fn test_main() {
	a := MyStruct{
		id:     'some id'
		result: SomeStruct{}
	}
	encoded_string := json.encode(a)
	assert encoded_string == '{"result":{},"id":"some id"}'
	test := decoder2.decode[MyStruct](encoded_string)!
	assert test == a
}
