import x.json2 as json
import x.json2.decoder2

struct Test {
	field MySumType
}

type MyInt = int
type MyString = string
type MySumType = MyString | int | string

fn test_alias_to_primitive() {
	mut test := Test{
		field: MyString('foo')
	}
	mut encoded := json.encode(test)
	assert dump(encoded) == '{"field":"foo"}'
	assert decoder2.decode[Test]('{"field":	"foo"}')!.field == MySumType('foo')

	test = Test{
		field: 'foo'
	}
	encoded = json.encode(test)
	assert dump(encoded) == '{"field":"foo"}'
	assert decoder2.decode[Test]('{"field":"foo"}')! == test

	test = Test{
		field: 1
	}
	encoded = json.encode(test)
	assert dump(encoded) == '{"field":1}'
	assert decoder2.decode[Test]('{"field":1}')! == test

	mut test2 := MyString('foo')
	encoded = json.encode(test2)
	assert dump(encoded) == '"foo"'

	mut test3 := MyInt(1000)
	encoded = json.encode(test3)
	assert dump(encoded) == '1000'
}
