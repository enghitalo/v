module main

import x.json2 as json
import x.json2.decoder2

struct Json2 {
	inner []f64
}

struct Json {
	Json2
	test f64
}

fn test_main() {
	str := '{
		"inner": [1, 2, 3, 4, 5],
		"test": 1.0
	}'
	data := decoder2.decode[Json](str) or {
		eprintln('Failed to decode json, error: ${err}')
		return
	}
	println(data)
	assert data.inner.len == 5
	assert data.inner[0] == 1.0
	assert data.inner[4] == 5.0
	assert data.test == 1.0
}
