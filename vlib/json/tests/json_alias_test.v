import x.json2 as json
import x.json2.decoder2

pub struct User {
	name   string
	age    int
	height f64
}

type Users = map[string]User

const json_users = '{
	"tom": { "name": "Tom", "age": 45, "height": 1.97 },
	"martin": { "name": "Martin", "age": 40, "height": 1.8 }
}'

fn test_alias_with_map() {
	a := decoder2.decode[map[string]User](json_users)!
	b := decoder2.decode[Users](json_users)!

	assert Users(a) == b

	c := json.encode(a)
	d := json.encode(b)

	assert c == d
}
