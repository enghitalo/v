import x.json2 as json
import x.json2.decoder2

struct Base {
	options  Options
	profiles Profiles
}

struct Options {
	cfg [6]u8
}

struct Profiles {
	cfg [4][7]u8
}

fn test_main() {
	a := json.encode(Base{})
	println(a)
	assert a.contains('"cfg":[[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0]]')

	b := decoder2.decode[Base](a)!
	assert b.options.cfg.len == 6
	assert b.profiles.cfg.len == 4
	assert b.profiles.cfg[0].len == 7
}
