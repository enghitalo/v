import x.json2 as json
import x.json2.decoder2

pub struct StructB {
	kind  string
	value i32
}

fn test_json_i32() {
	struct_b := decoder2.decode[StructB]('{"kind": "Int32", "value": 100}')!
	assert struct_b == StructB{
		kind:  'Int32'
		value: 100
	}

	assert json.encode(struct_b) == '{"kind":"Int32","value":100}'
}
