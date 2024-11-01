import x.json2.decoder2 as json

struct Test {
	optional_alias  ?MyAlias  // primitive
	optional_struct ?MyAlias2 // complex
}

struct Complex {
	a int = 3
}

type MyAlias = int
type MyAlias2 = Complex

fn test_empty() {
	test := Test{}
	assert json.decode[Test]('{}')! == test
}

fn test_value() {
	test := Test{
		optional_alias: 1
	}
	assert json.decode[Test]('{"optional_alias":1}')! == test
}

fn test_value_2() {
	test := Test{
		optional_alias:  1
		optional_struct: Complex{
			a: 1
		}
	}
	assert json.decode[Test]('{"optional_alias":1,"optional_struct":{"a":1}}')! == test
}
