import x.json2 as json
import x.json2.decoder2

struct Test {
	optional_sumtype ?MySumtype
}

type MySumtype = int | string

fn test_simple() {
	test := Test{}
	encoded := json.encode(test)
	assert dump(encoded) == '{}'
}
