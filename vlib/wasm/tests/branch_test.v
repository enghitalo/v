module main

import wasm

fn test_br_instructions() {
	mut m := wasm.Module{}
	
	// Test direct br instruction
	mut func1 := m.new_function('test_br', [], [.i32_t])
	{
		func1.i32_const(1)
		blk := func1.c_block([], [.i32_t])
		{
			func1.i32_const(2)
			func1.br(0) // branch to block
			func1.i32_const(3) // unreachable
		}
		func1.c_end(blk)
	}
	m.commit(func1, true)
	
	// Test br_if instruction
	mut func2 := m.new_function('test_br_if', [.i32_t], [.i32_t])
	{
		func2.i32_const(10)
		blk := func2.c_block([], [.i32_t])
		{
			func2.i32_const(20)
			func2.local_get(0)
			func2.br_if(0) // conditional branch
			func2.drop()
			func2.i32_const(30)
		}
		func2.c_end(blk)
	}
	m.commit(func2, true)
	
	// Test br_table instruction
	mut func3 := m.new_function('test_br_table', [.i32_t], [.i32_t])
	{
		blk0 := func3.c_block([], [.i32_t])
		{
			blk1 := func3.c_block([], [])
			{
				blk2 := func3.c_block([], [])
				{
					func3.local_get(0)
					func3.br_table([u32(0), u32(1)], u32(2))
				}
				func3.c_end(blk2)
				func3.i32_const(2)
				func3.c_br(blk0)
			}
			func3.c_end(blk1)
			func3.i32_const(1)
			func3.c_br(blk0)
		}
		func3.c_end(blk0)
		func3.i32_const(0)
	}
	m.commit(func3, true)
	
	code := m.compile()
	assert code.len > 0
	
	validate(code) or { panic(err) }
}

fn test_i32_comparison_shortcuts() {
	mut m := wasm.Module{}
	
	// Test various comparison shortcuts
	mut func := m.new_function('test_comparisons', [.i32_t, .i32_t], [.i32_t])
	{
		// Test i32_eq
		func.local_get(0)
		func.local_get(1)
		func.i32_eq()
		
		// Test i32_ne
		func.local_get(0)
		func.local_get(1)
		func.i32_ne()
		func.b_and(.i32_t)
		
		// Test i32_lt_s
		func.local_get(0)
		func.local_get(1)
		func.i32_lt_s()
		func.b_or(.i32_t)
		
		// Test i32_gt_s
		func.local_get(0)
		func.local_get(1)
		func.i32_gt_s()
		func.b_or(.i32_t)
	}
	m.commit(func, true)
	
	code := m.compile()
	assert code.len > 0
	
	validate(code) or { panic(err) }
}
