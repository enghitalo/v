module main

import wasm

fn test_table_section() {
	mut m := wasm.Module{}
	
	// Create a simple function to reference in the table
	mut func1 := m.new_function('table_func', [], [.i32_t])
	{
		func1.i32_const(42)
	}
	m.commit(func1, false)
	
	// Create a table
	table_idx := m.new_table('my_table', true, 1, 10)
	
	// Create an element segment to initialize the table
	mut offset_expr := wasm.ConstExpression{}
	offset_expr.i32_const(0)
	m.new_element_segment(none, u32(table_idx), offset_expr, ['table_func'])
	
	code := m.compile()
	assert code.len > 0
	
	validate(code) or { panic(err) }
}

fn test_call_indirect() {
	mut m := wasm.Module{}
	
	// Create a function to call indirectly
	mut target := m.new_function('target', [], [.i32_t])
	{
		target.i32_const(99)
	}
	m.commit(target, false)
	
	// Create a table
	table_idx := m.new_table('func_table', false, 1, 10)
	
	// Initialize table with the target function
	mut offset_expr := wasm.ConstExpression{}
	offset_expr.i32_const(0)
	m.new_element_segment(none, u32(table_idx), offset_expr, ['target'])
	
	// Create a function that does an indirect call
	// Use the same type as 'target': [] -> [.i32_t]
	mut caller := m.new_function('caller', [], [.i32_t])
	{
		caller.i32_const(0) // table index
		// The type index should be 0 (first function type registered)
		caller.call_indirect(0, u32(table_idx))
	}
	m.commit(caller, true)
	
	code := m.compile()
	assert code.len > 0
	
	validate(code) or { panic(err) }
}
