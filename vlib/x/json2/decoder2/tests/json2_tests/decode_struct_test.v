import x.json2.decoder2
import x.json2
import time

const fixed_time = time.new(
	year:   2022
	month:  3
	day:    11
	hour:   13
	minute: 54
	second: 25
)

type StringAlias = string
type BoolAlias = bool
type IntAlias = int

type SumTypes = bool | int | string

enum Enumerates {
	a
	b
	c
	d
	e = 99
	f
}

struct StructType[T] {
mut:
	val T
}

struct StructTypeSub {
	test string
}

struct StructTypeOption[T] {
mut:
	val ?T
}

struct StructTypePointer[T] {
mut:
	val &T
}

struct StructTypeSkippedFields[T] {
mut:
	val  T @[json: '-']
	val1 T
	val2 T @[json: '-']
	val3 T
}

struct StructTypeSkippedFields2[T] {
mut:
	val  T
	val1 T @[json: '-']
	val2 T
	val3 T @[json: '-']
}

struct StructTypeSkippedFields3[T] {
mut:
	val  T @[json: '-']
	val1 T @[json: '-']
	val2 T @[json: '-']
	val3 T @[json: '-']
}

struct StructTypeSkippedField4 {
mut:
	val map[string]string @[json: '-']
}

struct StructTypeSkippedFields5[T] {
mut:
	val  T @[skip]
	val1 T @[skip]
	val2 T @[skip]
	val3 T @[skip]
}

struct StructTypeSkippedFields6[T] {
mut:
	val  T
	val1 T @[skip]
	val2 T
	val3 T @[skip]
}

fn test_types() {
	assert decoder2.decode[StructType[string]]('{"val": ""}')!.val == ''
	assert decoder2.decode[StructType[string]]('{"val": "0"}')!.val == '0'
	assert decoder2.decode[StructType[string]]('{"val": "1"}')!.val == '1'
	assert decoder2.decode[StructType[string]]('{"val": "2"}')!.val == '2'
	// assert decoder2.decode[StructType[string]]('{"val": 0}')!.val == '0' // This should be a error
	// assert decoder2.decode[StructType[string]]('{"val": 1}')!.val == '1' // This should be a error
	// assert decoder2.decode[StructType[string]]('{"val": 2}')!.val == '2' // This should be a error
	assert decoder2.decode[StructType[string]]('{"val": "true"}')!.val == 'true'
	assert decoder2.decode[StructType[string]]('{"val": "false"}')!.val == 'false'
	// assert decoder2.decode[StructType[string]]('{"val": true}')!.val == 'true' // This should be a error
	// assert decoder2.decode[StructType[string]]('{"val": false}')!.val == 'false' // This should be a error

	// assert decoder2.decode[StructType[bool]]('{"val": ""}')!.val == false // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": "0"}')!.val == false // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": "1"}')!.val == true // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": "2"}')!.val == true // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": 0}')!.val == false // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": 1}')!.val == true // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": 2}')!.val == true // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": "true"}')!.val == true // This should be a error
	// assert decoder2.decode[StructType[bool]]('{"val": "false"}')!.val == false // This should be a error
	assert decoder2.decode[StructType[bool]]('{"val": true}')!.val == true
	assert decoder2.decode[StructType[bool]]('{"val": false}')!.val == false

	// assert decoder2.decode[StructType[int]]('{"val": ""}')!.val == 0 // This should be a error
	// assert decoder2.decode[StructType[int]]('{"val": "0"}')!.val == 0 // This should be a error
	// assert decoder2.decode[StructType[int]]('{"val": "1"}')!.val == 1 // This should be a error
	// assert decoder2.decode[StructType[int]]('{"val": "2"}')!.val == 2 // This should be a error
	assert decoder2.decode[StructType[int]]('{"val": 0}')!.val == 0
	assert decoder2.decode[StructType[int]]('{"val": 1}')!.val == 1
	assert decoder2.decode[StructType[int]]('{"val": 2}')!.val == 2
	// assert decoder2.decode[StructType[int]]('{"val": "true"}')!.val == 0 // This should be a error
	// assert decoder2.decode[StructType[int]]('{"val": "false"}')!.val == 0 // This should be a error
	// assert decoder2.decode[StructType[int]]('{"val": true}')!.val == 1 // This should be a error
	// assert decoder2.decode[StructType[int]]('{"val": false}')!.val == 0 // This should be a error

	assert decoder2.decode[StructType[time.Time]]('{"val": "2022-03-11T13:54:25.000Z"}')!.val == fixed_time
	assert decoder2.decode[StructType[time.Time]]('{"val": "2001-01-05"}')!.val.year == 2001
	assert decoder2.decode[StructType[time.Time]]('{"val": "2001-01-05"}')!.val.month == 1
	assert decoder2.decode[StructType[time.Time]]('{"val": "2001-01-05"}')!.val.day == 5
	assert decoder2.decode[StructType[time.Time]]('{"val": "2001-01-05"}')!.val.hour == 0
	assert decoder2.decode[StructType[time.Time]]('{"val": "2001-01-05"}')!.val.minute == 0
	assert decoder2.decode[StructType[time.Time]]('{"val": "2001-01-05"}')!.val.second == 0

	assert decoder2.decode[StructType[StructTypeSub]]('{"val": {"test": "test"}}')!.val.test == 'test'

	assert decoder2.decode[StructType[Enumerates]]('{"val": 0}')!.val == .a
	assert decoder2.decode[StructType[Enumerates]]('{"val": 1}')!.val == .b
	assert decoder2.decode[StructType[Enumerates]]('{"val": 99}')!.val == .e
	assert decoder2.decode[StructType[Enumerates]]('{}')!.val == .a

	if x := decoder2.decode[StructTypeOption[Enumerates]]('{"val": 0}')!.val {
		assert x == .a
	}
	if x := decoder2.decode[StructTypeOption[Enumerates]]('{"val": 1}')!.val {
		assert x == .b
	}
	if x := decoder2.decode[StructTypeOption[Enumerates]]('{"val": 99}')!.val {
		assert x == .e
	}
	if x := decoder2.decode[StructTypeOption[Enumerates]]('{}')!.val {
		assert false
	} else {
		assert true
	}
}

fn test_skipped_fields() {
	if x := decoder2.decode[StructTypeSkippedFields[int]]('{"val":10,"val1":10,"val2":10,"val3":10}') {
		assert x.val == 0
		assert x.val1 == 10
		assert x.val2 == 0
		assert x.val3 == 10
	} else {
		assert false
	}

	if x := decoder2.decode[StructTypeSkippedFields2[int]]('{"val":10,"val1":10,"val2":10,"val3":10}') {
		assert x.val == 10
		assert x.val1 == 0
		assert x.val2 == 10
		assert x.val3 == 0
	} else {
		assert false
	}

	if x := decoder2.decode[StructTypeSkippedFields3[int]]('{"val":10,"val1":10,"val2":10,"val3":10}') {
		assert x.val == 0
		assert x.val1 == 0
		assert x.val2 == 0
		assert x.val3 == 0
	} else {
		assert false
	}

	if x := decoder2.decode[StructTypeSkippedField4]('{"val":{"a":"b"}}') {
		assert x.val.len == 0
	} else {
		assert false
	}

	if x := decoder2.decode[StructTypeSkippedFields5[int]]('{"val":10,"val1":10,"val2":10,"val3":10}') {
		assert x.val == 0
		assert x.val1 == 0
		assert x.val2 == 0
		assert x.val3 == 0
	} else {
		assert false
	}

	if x := decoder2.decode[StructTypeSkippedFields6[int]]('{"val":10,"val1":10,"val2":10,"val3":10}') {
		assert x.val == 10
		assert x.val1 == 0
		assert x.val2 == 10
		assert x.val3 == 0
	} else {
		assert false
	}
}
