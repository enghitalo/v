import x.json2 as json
import x.json2.decoder2

fn test_calling_functions_with_map_initializations_containing_arrays() {
	result := json.encode({
		// Note: []string{} should NOT be treated as []json.string{}
		'users':  []string{}
		'groups': []string{}
	})
	assert result == '{"users":[],"groups":[]}'
}
