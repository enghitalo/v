import x.json2.decoder2
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
type TimeAlias = time.Time
type StructAlias = StructType[int]
type EnumAlias = Enumerates

type SumTypes = StructType[string] | []SumTypes | []string | bool | string | time.Time | u32

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

struct StructTypeOption[T] {
mut:
	val ?T
}

struct StructTypePointer[T] {
mut:
	val &T
}

fn test_types() {
	assert decoder2.decode[StructType[string]]('{"val": ""}')!.val == ''

	assert decoder2.decode[StructType[string]]('{"val": "2"}')!.val == '2'

	assert decoder2.decode[StructType[int]]('{"val": 2}')!.val == 2

	assert decoder2.decode[StructType[map[string]string]]('{"val": {"val1": "test"}}')!.val['val1'] == 'test'

	assert decoder2.decode[StructType[Enumerates]]('{"val": 0}')!.val == Enumerates.a
	assert decoder2.decode[StructType[Enumerates]]('{"val": 1}')!.val == Enumerates.b

	assert decoder2.decode[StructType[StringAlias]]('{"val": "2"}')!.val == StringAlias('2')
	assert decoder2.decode[StructType[BoolAlias]]('{"val": true}')!.val == BoolAlias(true)
	assert decoder2.decode[StructType[IntAlias]]('{"val": 2}')!.val == IntAlias(2)
	assert decoder2.decode[StructType[TimeAlias]]('{"val": "2022-03-11T13:54:25.000Z"}')!.val == TimeAlias(fixed_time)
	assert decoder2.decode[StructType[TimeAlias]]('{"val": "2022-03-11T13:54:25.000Z"}')!.val.unix() == fixed_time.unix()
	assert decoder2.decode[StructType[StructAlias]]('{"val": {"val": 2}}')!.val == StructAlias(StructType[int]{
		val: 2
	})
	assert decoder2.decode[StructAlias]('{"val": 2}')!.val == 2
	assert decoder2.decode[StructType[EnumAlias]]('{"val": 0}')!.val == EnumAlias(Enumerates.a)
	assert decoder2.decode[StructType[EnumAlias]]('{"val": 1}')!.val == EnumAlias(Enumerates.b)

	assert decoder2.decode[StructType[time.Time]]('{"val": "2022-03-11T13:54:25.000Z"}')!.val == fixed_time
	assert decoder2.decode[StructType[time.Time]]('{"val": "2022-03-11T13:54:25.000Z"}')!.val.unix() == fixed_time.unix()
}

fn test_option_types() {
	if x := decoder2.decode[StructTypeOption[string]]('{}')!.val {
		assert false, 'Should return none'
	} else {
		assert err.msg() == ''
		assert true
	}

	if x := decoder2.decode[StructTypeOption[string]]('{"val": "2"}')!.val {
		assert x == '2'
	} else {
		assert false, 'Should not return none'
	}
}
