module main

import x.json2.decoder2
import x.json2

pub struct Data {
	name string
	data [][]f64
}

fn test_main() {
	json_data := '{"name":"test","data":[[1,2,3],[4,5,6]]}'
	info := decoder2.decode[Data](json_data)!
	info2 := json2.decode[Data](json_data)!
	assert info == info2
}
