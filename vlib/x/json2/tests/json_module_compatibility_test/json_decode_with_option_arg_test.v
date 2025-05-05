import x.json2 as json
import x.json2.decoder2
import os

struct DbConfig {}

fn test_json_decode_with_option_arg() {
	if ret := print_info() {
		println(ret)
	} else {
		println(err)
	}
	assert true
}

fn print_info() !string {
	dbconf := decoder2.decode[DbConfig](os.read_file('dbconf.json')!)!
	println(dbconf)
	return '${dbconf}'
}
