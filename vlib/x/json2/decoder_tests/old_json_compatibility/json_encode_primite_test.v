import x.json2.decoder2 as json

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

	assert json.decode[Test]('{"field":	"foo"}')!.field == MySumType('foo')

	test = Test{
		field: 'foo'
	}

	assert json.decode[Test]('{"field":"foo"}')! == test

	test = Test{
		field: 1
	}

	assert json.decode[Test]('{"field":1}')! == test
}
