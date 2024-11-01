import x.json2.decoder2 as json

fn test_main() {
	json_text := '{ "a": "b" }'
	b := json.decode(struct {a, string}, json_text)!.a
	assert dump(b) == 'b'
}
