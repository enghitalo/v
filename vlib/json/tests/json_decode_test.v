import x.json2 as json
import x.json2.decoder2

struct TestTwin {
	id     int
	seed   string
	pubkey string
}

struct TestTwins {
mut:
	twins []TestTwin @[required]
}

fn test_json_decode_fails_to_decode_unrecognised_array_of_dicts() {
	data := '[{"twins":[{"id":123,"seed":"abcde","pubkey":"xyzasd"},{"id":456,"seed":"dfgdfgdfgd","pubkey":"skjldskljh45sdf"}]}]'
	decoder2.decode[TestTwins](data) or {
		assert err.msg() == 'Expected object, but got array'
		return
	}
	assert false
}

fn test_json_decode_works_with_a_dict_of_arrays() {
	data := '{"twins":[{"id":123,"seed":"abcde","pubkey":"xyzasd"},{"id":456,"seed":"dfgdfgdfgd","pubkey":"skjldskljh45sdf"}]}'
	res := decoder2.decode[TestTwins](data) or {
		assert false, err.msg()
		exit(1)
	}
	assert res.twins[0].id == 123
	assert res.twins[0].seed == 'abcde'
	assert res.twins[0].pubkey == 'xyzasd'
	assert res.twins[1].id == 456
	assert res.twins[1].seed == 'dfgdfgdfgd'
	assert res.twins[1].pubkey == 'skjldskljh45sdf'
}

struct Mount {
	size u64
}

fn test_decode_u64() {
	data := '{"size": 10737418240}'
	m := decoder2.decode[Mount](data)!
	assert m.size == 10737418240
	// println(m)
}

//

pub struct Comment {
pub mut:
	id      string
	comment string
}

pub struct Task {
mut:
	description    string
	id             int
	total_comments int
	file_name      string    @[skip]
	comments       []Comment @[skip]
	skip_field     string    @[json: '-']
}

fn test_skip_fields_should_be_initialised_by_json_decode() {
	data := '{"total_comments": 55, "id": 123}'
	mut task := decoder2.decode[Task](data)!
	assert task.id == 123
	assert task.total_comments == 55
	assert task.comments == []
}

fn test_skip_should_be_ignored() {
	data := '{"total_comments": 55, "id": 123, "skip_field": "foo"}'
	mut task := decoder2.decode[Task](data)!
	assert task.id == 123
	assert task.total_comments == 55
	assert task.comments == []
	assert task.skip_field == ''
}

//

struct DbConfig {
	host   string
	dbname string
	user   string
}

fn test_decode_error_message_should_have_enough_context_empty() {
	decoder2.decode[DbConfig]('') or {
		assert err.msg() == 'empty string'
		return
	}
	assert false
}

fn test_decode_error_message_should_have_enough_context_just_brace() {
	decoder2.decode[DbConfig]('{') or {
		// dump(json.encode(err.msg()))
		assert err.msg() == '\n{\n^ EOF error: expecting a complete object after `{`'
		return
	}
	assert false
}

fn test_decode_error_message_should_have_enough_context_trailing_comma_at_end() {
	txt := '{
    "host": "localhost",
    "dbname": "alex",
    "user": "alex",
}'
	decoder2.decode[DbConfig](txt) or {
		// dump(json.encode(err.msg()))
		assert err.msg() == '\n\n}\n ^ Expecting object key after `,`'
		return
	}
	assert false
}

fn test_decode_error_message_should_have_enough_context_in_the_middle() {
	txt := '{"host": "localhost", "dbname": "alex" "user": "alex", "port": "1234"}'
	decoder2.decode[DbConfig](txt) or {
		// dump(json.encode(err.msg()))
		assert err.msg() == '\n{"host": "localhost", "dbname": "alex" "\n                                       ^ invalid value. Unexpected character after string_ end'
		return
	}
	assert false
}
