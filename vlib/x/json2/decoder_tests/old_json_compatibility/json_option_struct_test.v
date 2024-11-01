import x.json2.decoder2 as json

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
	assert encoded_string == '{"result":{},"id":"some id"}'
	test := json.decode[MyStruct](encoded_string)!
	assert test == a
}
