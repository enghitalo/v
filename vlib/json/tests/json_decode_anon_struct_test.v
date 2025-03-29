import x.json2 as json
import x.json2.decoder2

fn test_main() {
	json_text := '{ "a": "b" }'
	b := decoder2.decode(struct {
		a string
	}, json_text)!.a
	assert dump(b) == 'b'
}
