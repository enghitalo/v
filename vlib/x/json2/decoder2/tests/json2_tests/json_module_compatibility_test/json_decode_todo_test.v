import x.json2.decoder2

struct Mount {
	size u64
}

fn test_decode_u64() {
	data := '{"size": 10737418240}'
	m := decoder2.decode[Mount](data)!
	assert m.size == 10737418240
}

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
}

fn test_skip_fields_should_be_initialised_by_json_decode() {
	data := '{"total_comments": 55, "id": 123}'
	mut task := decoder2.decode[Task](data)!
	assert task.id == 123
	assert task.total_comments == 55
	assert task.comments == []
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
		assert err.msg() == '
{
^ EOF error: expecting a complete object after `{`'
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
		assert err.msg() == '\n\n}\n ^ Expecting object key after `,`'

		return
	}
	assert false
}

fn test_decode_error_message_should_have_enough_context_in_the_middle() {
	txt := '{"host": "localhost", "dbname": "alex" "user": "alex", "port": "1234"}'
	decoder2.decode[DbConfig](txt) or {
		assert err.msg() == '\n{"host": "localhost", "dbname": "alex" "\n                                       ^ invalid value. Unexpected character after string_ end'
		return
	}
	assert false
}
