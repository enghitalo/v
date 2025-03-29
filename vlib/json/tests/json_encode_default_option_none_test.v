module main

import x.json2 as json
import x.json2.decoder2

struct Test {
	id ?string = none
}

fn test_main() {
	assert json.encode(Test{}) == '{}'
}
