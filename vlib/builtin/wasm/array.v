module builtin

// Helper functions for array operations
@[inline]
fn __at_least_one(how_many u64) u64 {
	// handle the case for allocating memory for empty structs, which have sizeof(EmptyStruct) == 0
	// in this case, just allocate a single byte, avoiding the panic for malloc(0)
	if how_many == 0 {
		return 1
	}
	return how_many
}

fn panic_on_negative_len(len int) {
	if len < 0 {
		panic('negative array length: ${len}')
	}
}

@[inline]
fn panic_on_negative_cap(cap int) {
	if cap < 0 {
		panic('negative array capacity: ${cap}')
	}
}

// array is a struct, used for denoting all array types in V.
// This is a WASM-specific definition that allows direct field access
// `.data` is a void pointer to the backing heap memory block,
// which avoids using generics and thus without generating extra
// code for every type.
pub struct array {
pub mut:
	data   voidptr
	offset int // in bytes (should be `usize`), to avoid copying data while making slices, unless it starts changing
	len    int // length of the array in elements.
	cap    int // capacity of the array in elements.
	flags  ArrayFlags
pub:
	element_size int // size in bytes of one element in the array.
}

@[flag]
pub enum ArrayFlags {
	noslices // when <<, `.noslices` will free the old data block immediately (you have to be sure, that there are *no slices* to that specific array). TODO: integrate with reference counting/compiler support for the static cases.
	noshrink // when `.noslices` and `.noshrink` are *both set*, .delete(x) will NOT allocate new memory and free the old. It will just move the elements in place, and adjust .len.
	nogrow   // the array will never be allowed to grow past `.cap`. set `.nogrow` and `.noshrink` for a truly fixed heap array
	nofree   // `.data` will never be freed
}

// Internal function, used by V (`nums := []int`)
fn __new_array(mylen int, cap int, elm_size int) array {
	panic_on_negative_len(mylen)
	panic_on_negative_cap(cap)
	cap_ := if cap < mylen { mylen } else { cap }
	arr := array{
		element_size: elm_size
		data:         vcalloc(u64(cap_) * u64(elm_size))
		len:          mylen
		cap:          cap_
	}
	return arr
}

fn __new_array_with_default(mylen int, cap int, elm_size int, val voidptr) array {
	panic_on_negative_len(mylen)
	panic_on_negative_cap(cap)
	cap_ := if cap < mylen { mylen } else { cap }
	mut arr := array{
		element_size: elm_size
		len:          mylen
		cap:          cap_
	}
	total_size := u64(cap_) * u64(elm_size)
	if cap_ > 0 && mylen == 0 {
		arr.data = unsafe { malloc(__at_least_one(total_size)) }
	} else {
		arr.data = vcalloc(total_size)
	}
	if val != 0 {
		mut eptr := &u8(arr.data)
		unsafe {
			if eptr != nil {
				if arr.element_size == 1 {
					byte_value := *(&u8(val))
					for i in 0 .. arr.len {
						eptr[i] = byte_value
					}
				} else {
					for _ in 0 .. arr.len {
						vmemcpy(eptr, val, arr.element_size)
						eptr += arr.element_size
					}
				}
			}
		}
	}
	return arr
}

// first returns the first element of the array.
// If the array is empty, this will panic.
pub fn (a array) first() voidptr {
	if a.len == 0 {
		panic('array.first: array is empty')
	}
	return a.data
}

// last returns the last element of the array.
// If the array is empty, this will panic.
pub fn (a array) last() voidptr {
	if a.len == 0 {
		panic('array.last: array is empty')
	}
	unsafe {
		return &u8(a.data) + u64(a.len - 1) * u64(a.element_size)
	}
}

// clone returns a deep copy of the array.
pub fn (a &array) clone() array {
	return unsafe { a.clone_to_depth(0) }
}

// recursively clone given array - `unsafe` when called directly because depth is not checked
@[unsafe]
pub fn (a &array) clone_to_depth(depth int) array {
	source_capacity_in_bytes := u64(a.cap) * u64(a.element_size)
	mut arr := array{
		element_size: a.element_size
		data:         vcalloc(source_capacity_in_bytes)
		len:          a.len
		cap:          a.cap
	}
	// Recursively clone-generated elements if array element is array type
	if depth > 0 && a.element_size == sizeof(array) && a.len >= 0 && a.cap >= a.len {
		ar := array{}
		asize := int(sizeof(array))
		for i in 0 .. a.len {
			unsafe { vmemcpy(&ar, a.get_unsafe(i), asize) }
			ar_clone := unsafe { ar.clone_to_depth(depth - 1) }
			unsafe { arr.set_unsafe(i, &ar_clone) }
		}
		return arr
	} else if depth > 0 && a.element_size == sizeof(string) && a.len >= 0 && a.cap >= a.len {
		for i in 0 .. a.len {
			str_ptr := unsafe { &string(a.get_unsafe(i)) }
			str_clone := (*str_ptr).clone()
			unsafe { arr.set_unsafe(i, &str_clone) }
		}
		return arr
	}
	// For primitive types or shallow copy, just copy the data
	if a.len > 0 {
		unsafe { vmemcpy(arr.data, a.data, u64(a.len) * u64(a.element_size)) }
	}
	return arr
}

// get_unsafe returns the element at index `i` without bounds checking.
@[unsafe]
pub fn (a array) get_unsafe(i int) voidptr {
	unsafe {
		return &u8(a.data) + u64(i) * u64(a.element_size)
	}
}

// set_unsafe sets the element at index `i` without bounds checking.
@[unsafe]
pub fn (a array) set_unsafe(i int, val voidptr) {
	unsafe {
		dest := &u8(a.data) + u64(i) * u64(a.element_size)
		vmemcpy(dest, val, a.element_size)
	}
}
