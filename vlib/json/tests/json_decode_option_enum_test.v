import x.json2 as json
import x.json2.decoder2

enum Lang {
	en = 1
}

struct Request {
	lang ?Lang // ?string, ?int are ok
}

fn test_main() {
	assert dump(decoder2.decode[Request]('{}')!) == Request{
		lang: ?Lang(none)
	}
	assert dump(decoder2.decode[Request]('{"lang": "en"}')!) == Request{
		lang: .en
	}
}
