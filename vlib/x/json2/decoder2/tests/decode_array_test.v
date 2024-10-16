import x.json2.decoder2 as json

fn test_array_of_strings() {
	assert json.decode[[]string]('["a", "b", "c"]')! == ['a', 'b', 'c']
	// assert json.decode[[]bool]('[true, false, true]')! == [true, false, true]
	// assert json.decode[[]int]('[1, 2, 3]')! == [1, 2, 3]
}
