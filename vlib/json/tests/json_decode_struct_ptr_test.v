import x.json2 as json
import x.json2.decoder2

struct Message {
mut:
	id       int
	text     string
	reply_to &Message
}

fn test_main() {
	mut json_data := '{"id": 1, "text": "Hello", "reply_to": {"id": 2, "text": "Hi"}}'
	mut message := decoder2.decode[Message](json_data)!
	assert message.reply_to.id == 2

	json_data = '{"id": 1, "text": "Hello", "reply_to": {"id": 2, "text": "Hi", "reply_to": {}}}'
	message = decoder2.decode[Message](json_data)!
	assert message.reply_to.reply_to.reply_to == unsafe { nil }

	json_data = '{"id": 1, "text": "Hello", "reply_to": {"id": 2, "text": "Hi", "reply_to": {"id": 5}}}'
	message = decoder2.decode[Message](json_data)!
	assert message.reply_to.reply_to.id == 5
}
