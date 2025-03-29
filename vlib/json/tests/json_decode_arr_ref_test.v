import x.json2 as json
import x.json2.decoder2

struct Test {
	a string
}

fn test_main() {
	x := decoder2.decode[[]&Test]('[{"a":"a"}]') or { exit(1) }
	assert x[0].a == 'a'
}
