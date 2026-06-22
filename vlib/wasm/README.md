## Description

The `wasm` module is a pure V implementation of the WebAssembly bytecode module format,
available in the form of a builder.

It allows users to generate WebAssembly modules in memory.

With the V wasm module, users can create functions, opcodes, and utilize the entire wasm
specification without the need for a large dependency like binaryen. All of this
functionality is available within V itself, making the module a valuable resource for
V developers seeking to build high-performance web applications.

The module is designed to generate a `[]u8`, which can be written to a `.wasm` file
or executed in memory.

Examples are present in `examples/wasm_codegen`.

```v
import wasm
import os

fn main() {
	mut m := wasm.Module{}
	mut func := m.new_function('add', [.i32_t, .i32_t], [.i32_t])
	{
		func.local_get(0) // | local.get 0
		func.local_get(1) // | local.get 1
		func.add(.i32_t) // | i32.add
	}
	m.commit(func, true) // `export: true`

	mod := m.compile() // []u8

	os.write_file_array('add.wasm', mod)!
}
```

This module does not perform verification of the WebAssembly output.
Use a tool like `wasm-validate` to validate, and `wasm-dis` to show a decompiled form.

## New Features (Phase 1 - 2026)

### Tables and Indirect Calls

Tables allow dynamic function dispatch through indirect calls:

```v
mut m := wasm.Module{}

// Create a function to call indirectly
mut target := m.new_function('target', [], [.i32_t])
{
	target.i32_const(42)
}
m.commit(target, false)

// Create a table
table_idx := m.new_table('func_table', false, 1, 10)

// Initialize table with the target function
mut offset := wasm.ConstExpression{}
offset.i32_const(0)
m.new_element_segment(none, u32(table_idx), offset, ['target'])

// Call indirectly through the table
mut caller := m.new_function('caller', [], [.i32_t])
{
	caller.i32_const(0) // table index
	caller.call_indirect(0, u32(table_idx))
}
m.commit(caller, true)
```

### WASI Support

Easily import WASI functions for system interactions:

```v
mut m := wasm.Module{}

// Add WASI imports
m.add_wasi_import('fd_write')
m.add_wasi_import('proc_exit')

mut func := m.new_function('hello', [], [])
{
	// Use fd_write to print to stdout
	func.i32_const(1) // fd (stdout)
	func.i32_const(0) // iovs pointer
	func.i32_const(1) // iovs_len
	func.i32_const(0) // nwritten pointer
	func.call_import('wasi_snapshot_preview1', 'fd_write')
}
m.commit(func, true)
```

Supported WASI functions: `fd_write`, `proc_exit`, `args_get`, `args_sizes_get`, `environ_get`, `environ_sizes_get`, `clock_time_get`, `random_get`.

### Enhanced Control Flow

New branch instructions for more flexible control flow:

```v
mut func := m.new_function('branch_demo', [.i32_t], [.i32_t])
{
	// Direct branch
	func.br(0)
	
	// Conditional branch
	func.local_get(0)
	func.br_if(0)
	
	// Branch table (switch-case)
	func.local_get(0)
	func.br_table([u32(0), u32(1)], u32(2))
}
```

### i32 Comparison Shortcuts

Convenient shortcuts for common i32 comparisons:

```v
func.local_get(0)
func.local_get(1)
func.i32_eq()  // i32.eq
func.i32_lt_s() // i32.lt_s (signed)
func.i32_gt_u() // i32.gt_u (unsigned)
// Also available: i32_ne, i32_le_s, i32_le_u, i32_ge_s, i32_ge_u
```
