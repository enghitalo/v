module main

import wasm

fn test_wasi_fd_write() {
	mut m := wasm.Module{}
	
	// Add WASI fd_write import
	fd_write_idx := m.add_wasi_import('fd_write')
	
	// Create a function that uses fd_write
	mut func := m.new_function('write_test', [], [.i32_t])
	{
		func.i32_const(1) // fd (stdout)
		func.i32_const(0) // iovs pointer
		func.i32_const(1) // iovs_len
		func.i32_const(0) // nwritten pointer
		func.call_import('wasi_snapshot_preview1', 'fd_write')
	}
	m.commit(func, true)
	
	code := m.compile()
	assert code.len > 0
	
	validate(code) or { panic(err) }
}

fn test_wasi_proc_exit() {
	mut m := wasm.Module{}
	
	// Add WASI proc_exit import
	m.add_wasi_import('proc_exit')
	
	// Create a function that exits
	mut func := m.new_function('exit_test', [], [])
	{
		func.i32_const(0) // exit code
		func.call_import('wasi_snapshot_preview1', 'proc_exit')
	}
	m.commit(func, true)
	
	code := m.compile()
	assert code.len > 0
	
	validate(code) or { panic(err) }
}

fn test_wasi_multiple_imports() {
	mut m := wasm.Module{}
	
	// Add multiple WASI imports
	m.add_wasi_import('fd_write')
	m.add_wasi_import('proc_exit')
	m.add_wasi_import('args_get')
	m.add_wasi_import('environ_get')
	
	// Create a simple function
	mut func := m.new_function('test', [], [])
	{
		func.nop()
	}
	m.commit(func, true)
	
	code := m.compile()
	assert code.len > 0
	
	validate(code) or { panic(err) }
}
