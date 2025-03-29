import x.json2 as json
import x.json2.decoder2

struct TodoDto {
	foo int
}

fn test_decode_with_encode_arg() {
	body := TodoDto{}
	ret := decoder2.decode[TodoDto](json.encode(body))!
	println(ret)
	assert ret.foo == 0
}
