module builtin

// vwasm_heap_base returns the base address of the heap.
pub fn vwasm_heap_base() voidptr {
	mut rval := unsafe { nil }
	asm wasm {
		global.get __heap_base
		local.set rval
		; =r (rval)
	}
	return rval
}

// vwasm_heap_size returns the size of the main wasm memory in pages.
// Analogous to the `memory.size` instruction.
pub fn vwasm_memory_size() int {
	mut rval := 0
	asm wasm {
		memory.size
		local.set rval
		; =r (rval)
	}
	return rval
}

// vwasm_memory_grow grows the main wasm memory by `size` pages.
// Analogous to the `memory.grow` instruction.
pub fn vwasm_memory_grow(size int) int {
	mut rval := 0
	asm wasm {
		local.get size
		memory.grow
		local.set rval
		; =r (rval)
		; r (size)
	}
	return rval
}

// vcalloc dynamically allocates a zeroed `n` bytes block of memory on the heap.
// vcalloc returns a `byteptr` pointing to the memory address of the allocated space.
// vcalloc checks for negative values given in `n`.
@[unsafe]
pub fn vcalloc(n isize) &u8 {
	if n <= 0 {
		$if no_imports ? {
			return unsafe { nil }
		} $else {
			panic('valloc(n <= 0)')
		}
	}

	res := unsafe { malloc(n) }

	asm wasm {
		local.get res
		i32.const 0x0
		local.get n
		memory.fill
		; ; r (res)
		  r (n)
	}

	return res
}

// isnil returns true if an object is nil (only for C objects).
@[inline]
pub fn isnil(v voidptr) bool {
	return v == 0
}

// vmemcpy copies n bytes from memory area src to memory area dest.
// The memory areas **CAN** overlap. vmemcpy returns a pointer to `dest`.
@[unsafe]
pub fn vmemcpy(dest voidptr, const_src voidptr, n isize) voidptr {
	asm wasm {
		local.get dest
		local.get const_src
		local.get n
		memory.copy
		; ; r (dest)
		  r (const_src)
		  r (n)
	}
	return dest
}

// vmemmove copies n bytes from memory area src to memory area dest.
// The memory areas **CAN** overlap. vmemmove returns a pointer to `dest`.
@[unsafe]
pub fn vmemmove(dest voidptr, const_src voidptr, n isize) voidptr {
	asm wasm {
		local.get dest
		local.get const_src
		local.get n
		memory.copy
		; ; r (dest)
		  r (const_src)
		  r (n)
	}
	return dest
}

// vmemset fills the first `n` bytes of the memory area pointed to by `s`,
// with the constant byte `c`. It returns a pointer to the memory area `s`.
@[unsafe]
pub fn vmemset(s voidptr, c int, n isize) voidptr {
	asm wasm {
		local.get s
		local.get c
		local.get n
		memory.fill
		; ; r (s)
		  r (c)
		  r (n)
	}
	return s
}

// vmemcmp compares two memory regions byte by byte
// Returns 0 if equal, <0 if a < b, >0 if a > b
// This is an efficient WASM-optimized implementation
@[unsafe]
pub fn vmemcmp(a voidptr, b voidptr, n int) int {
	if n == 0 {
		return 0
	}
	if a == b {
		return 0
	}
	
	a_bytes := unsafe { &u8(a) }
	b_bytes := unsafe { &u8(b) }
	
	// Process 8 bytes at a time for better performance on WASM
	mut i := 0
	n_aligned := n - (n % 8)
	
	// Compare 8 bytes at a time using i64 comparison
	for i < n_aligned {
		a_i64 := unsafe { &i64(a_bytes + i) }
		b_i64 := unsafe { &i64(b_bytes + i) }
		if unsafe { *a_i64 != *b_i64 } {
			// Fall back to byte-by-byte comparison for this chunk
			for j in 0 .. 8 {
				idx := i + j
				a_byte := unsafe { a_bytes[idx] }
				b_byte := unsafe { b_bytes[idx] }
				if a_byte != b_byte {
					return int(a_byte) - int(b_byte)
				}
			}
		}
		i += 8
	}
	
	// Handle remaining bytes
	for i < n {
		a_byte := unsafe { a_bytes[i] }
		b_byte := unsafe { b_bytes[i] }
		if a_byte != b_byte {
			return int(a_byte) - int(b_byte)
		}
		i++
	}
	
	return 0
}
