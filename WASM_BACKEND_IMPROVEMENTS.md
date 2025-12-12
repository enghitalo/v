# WASM Backend and AST Improvements for Dynamic Arrays and Option/Result Support

This document outlines the necessary improvements to the V WASM backend and AST to support dynamic arrays and option/result types.

## Current Status

### Supported Features
- Fixed-size arrays (`[N]Type`)
- Primitive types (int, i64, f32, f64, bool, etc.)
- Structs
- Pointers
- Static memory allocation
- String type (backed by fixed structure)

### Unsupported Features
- Dynamic arrays (`[]Type`)
- Option types (`?Type`)
- Result types (`!Type` / error handling)
- Dynamic memory reallocation
- Array growth operations

## 1. Dynamic Array Support

### 1.1 AST Layer Improvements

#### Current Array Representation
The AST currently has two array types defined in `vlib/v/ast/types.v`:

```v
pub struct Array {
pub:
    nr_dims int
pub mut:
    elem_type Type
}

pub struct ArrayFixed {
pub:
    size      int
    size_expr Expr
pub mut:
    elem_type Type
    is_fn_ret bool
}
```

**Issue**: The `Array` type exists in AST but is not fully utilized by the WASM backend.

#### Required Improvements

1. **Array Runtime Representation**
   - Location: `vlib/builtin/array.v`
   - The `array` struct already exists with 6 fields:
     - `data: voidptr` - pointer to heap-allocated data block
     - `offset: int` - offset in bytes for slicing support (avoids copying)
     - `len: int` - current length in elements
     - `cap: int` - capacity in elements
     - `flags: ArrayFlags` - flags controlling growth/shrink behavior
     - `element_size: int` - size in bytes of one element
   - **Total struct size**: ~24-28 bytes (6 fields: 5 ints + 1 pointer on 32-bit WASM)
   - **Memory layout**: Array header is stack/heap allocated, points to separate heap block for data

2. **Type Size Calculation**
   - Location: `vlib/v/gen/wasm/serialise/types.v`
   - Add support for calculating size of `array` struct (should be treated as a pointer in WASM)
   - The array header itself is a fixed-size structure, but it points to heap memory

### 1.2 WASM Backend Improvements

#### 1.2.1 Type Handling (`vlib/v/gen/wasm/ops.v`)

**Current Issue**: Line 755 in `gen.v` throws error:
```v
ast.Array {
    g.w_error('wasm backend does not support dynamic arrays')
}
```

**Required Changes**:

1. **Update `get_wasm_type()` in `ops.v`**:
   - Add case for `ast.Array` to return `.i32_t` (pointer to array struct)
   - Similar to how `ast.Struct` is handled

2. **Update `is_pure_type()` in `mem.v`**:
   - Arrays are NOT pure types (they require heap allocation)
   - Keep current behavior where arrays return `false`

#### 1.2.2 Array Operations (`vlib/v/gen/wasm/gen.v`)

**Required Implementations**:

1. **Array Initialization** (line ~723):
   ```v
   ast.ArrayInit {
       // Current: Creates local var and calls set_with_expr
       // Need to:
       // 1. Allocate array struct on stack or heap (24-28 bytes)
       // 2. Calculate total size: cap * element_size
       // 3. Call __new_array() or __new_array_with_default()
       // 4. Initialize elements if provided (loop and store each)
       // 5. Return pointer to array struct
   }
   ```

2. **Array Indexing with Bounds Checking** (line ~731-800):
   ```v
   ast.IndexExpr {
       // Current: Only handles ArrayFixed and strings
       // Need to add:
       ast.Array {
           // 1. Load array struct pointer
           // 2. Access .data field to get element pointer (offset 0)
           // 3. **BOUNDS CHECKING** - Critical for safety:
           //    a. Load index value to temporary local
           //    b. Load array.len from struct (i32.load offset=8)
           //    c. Check upper bound: index >= len (unsigned comparison)
           //    d. Check lower bound (implicit in unsigned: negative becomes large)
           //    e. If out of bounds:
           //       - Call eprintln() with error message including file:line
           //       - Call panic("index out of range")
           //    f. Use `if (index >= len) { panic }` pattern (similar to line 790-800)
           // 4. Calculate element offset: (index + array.offset) * element_size
           // 5. Load actual data pointer: array.data (i32.load offset=0)
           // 6. Load/store element at: data_ptr + calculated_offset
           //
           // **Optimization**: Skip bounds check if:
           //    - Inside `[direct_array_access]` function
           //    - Index is compile-time constant within bounds
           //    - Checker has already verified safety
       }
   }
   ```

2. **Array Indexing** (line ~731-800):
   ```v
   ast.IndexExpr {
       // Current: Only handles ArrayFixed and strings
       // Need to add:
       ast.Array {
           // 1. Load array struct pointer
           // 2. Access .data field to get element pointer (offset 0)
           // 3. Bounds check using .len field (offset 8):
           //    - Load index value to local
           //    - Load array.len 
           //    - Compare: if index >= len || index < 0, call panic()
           // 4. Calculate element offset: (index + array.offset) * element_size
           // 5. Load/store element at: array.data + calculated_offset
       }
   }
   ```

3. **Array Methods** - Essential operations to implement:
   - **`push(element)`**: 
     - Check if len == cap, grow if needed
     - Store element at data[len * element_size]
     - Increment len
   - **`pop()`**: 
     - Check len > 0, panic if empty
     - Decrement len
     - Return element at data[len * element_size]
   - **`<< operator`** (append): Same as push
   - **`delete(index)`**: 
     - Bounds check
     - Shift elements: memcpy(data+index, data+index+1, (len-index-1) * elem_size)
     - Decrement len
   - **`insert(index, element)`**: 
     - Ensure capacity
     - Shift elements right
     - Store element
     - Increment len
   - **`clone()`**: 
     - Allocate new array with same cap
     - Deep copy data block: vmemcpy(new.data, old.data, len * elem_size)
   - **`filter()`, `map()`, `any()`, `all()`**: Higher order functions (Phase 5)

#### 1.2.3 Memory Management (`vlib/v/gen/wasm/mem.v`)

**Required Additions**:

1. **Heap Allocation Functions**:
   - **malloc/free equivalents**: The WASM backend uses `vcalloc()` and `malloc()` from `vlib/builtin/wasm/builtin.v`
   - `vcalloc(n)` - allocate zeroed memory, already implemented using WASM `memory.fill`
   - `malloc(n)` - allocate uninitialized memory (needs implementation or import)
   - `free(ptr)` - deallocate memory (needs implementation or stub for now)
   - Integration with WASM linear memory model and heap management

2. **Array Allocation Helpers**:
   - The WASM backend needs to call builtin functions:
     - `__new_array(len, cap, element_size)` - allocate new array
     - `__new_array_with_default(len, cap, element_size, default_val)` - with default
     - `__new_array_with_multi_default(len, cap, element_size, default_val)` - for complex types
   - These are defined in `vlib/builtin/array.v`
   - Need to ensure these functions are available in WASM context

3. **Field Access Helpers**:
   - Add helper functions to access array struct fields:
     - `load_array_len(arr_ptr)` - get length field (offset +8 bytes)
     - `load_array_cap(arr_ptr)` - get capacity field (offset +12 bytes)  
     - `load_array_data(arr_ptr)` - get data pointer (offset +0 bytes)
     - `load_array_offset(arr_ptr)` - get offset field (offset +4 bytes)
     - `store_array_len(arr_ptr, len)` - set length field
   - Field offsets based on struct layout: data(0), offset(4), len(8), cap(12), flags(16), element_size(20)

4. **Array Reallocation and Growth**:
   - Implement or call `array_ensure_cap(arr, required_cap)` for growth operations
   - Growth strategy (from `vlib/builtin/array.v`):
     ```
     new_cap = if cap < required { required } else { cap * 2 }
     ```
   - Handle memory copying during reallocation:
     - Allocate new data block with `vcalloc(new_cap * element_size)`
     - Copy existing data using `vmemcpy(new_data, old_data, len * element_size)`
     - Update array struct fields (data, cap)
     - Free old data block (when memory management is available)
   - Respect `ArrayFlags.nogrow` flag - error if growth attempted when set

#### 1.2.4 Runtime Support (`vlib/builtin/wasm/`)

**Files to Modify**:

1. `vlib/builtin/wasm/builtin.v`:
   - Add array allocation functions if not using generic ones
   - Ensure `vcalloc()`, `vmemcpy()`, `vmemset()` work correctly

2. Consider creating `vlib/builtin/wasm/array.v`:
   - WASM-specific array helper functions
   - Optimized versions of common operations

### 1.3 Integration Points in `gen.v`

**Multiple locations in `gen.v` need updates to handle dynamic arrays**:

1. **Line ~755**: Remove error, add Array handling in IndexExpr
   ```v
   ast.Array {
       // Currently: g.w_error('wasm backend does not support dynamic arrays')
       // Change to: Handle array indexing with bounds checking (see section 1.2.2)
   }
   ```

2. **Line ~723**: ArrayInit expression handling
   - Already partially implemented for fixed arrays
   - Extend to call `__new_array()` for dynamic arrays

3. **Function calls involving arrays**:
   - Passing arrays as parameters (pass pointer to array struct)
   - Returning arrays from functions (return pointer)
   - Array assignments (copy pointer, not deep copy unless clone())

4. **Array field access in structs**:
   - When struct contains array field, store as array struct
   - Load/store entire array struct (24-28 bytes)

5. **Array comparisons**:
   - `arr1 == arr2` should compare elements, not pointers
   - May need to call array comparison helper

6. **Array in expressions**:
   - Binary operations involving arrays
   - Array concatenation
   - Array slicing `arr[start..end]`

### 1.4 Module Layer (`vlib/wasm/`)

**No changes required** - The `wasm` module is for generating WASM bytecode and already supports all necessary instructions (memory operations, function calls, etc.)

## 2. Option/Result Type Support

### 2.1 Current Limitations

From `vlib/v/gen/wasm/gen.v`:
- Line 150-151: "interop functions must not return option or result"
- Line 241-242: "option types are not implemented"
- Line 260-261: "returning a void option is forbidden"
- Line 265-266: "result types are not implemented"

### 2.2 Option/Result Runtime Representation

From `vlib/builtin/chan_option_result.v`:

```v
struct Option {
    state u8       // 0 = ok, 1 = error, 2 = none
    err   IError   // error object or none__
    // Data follows after err field
}

struct _result {
    is_error bool
    err      IError
    // Data follows after err field
}
```

### 2.3 AST Type Flags

From `vlib/v/ast/types.v`:

```v
pub enum TypeFlag as u32 {
    option             = 1 << 24
    result             = 1 << 25
    // ...
}
```

**Key Methods**:
- `Type.has_flag(.option)` - check if type is optional
- `Type.has_flag(.result)` - check if type is result
- `Type.has_option_or_result()` - check for either
- `Type.clear_option_and_result()` - get base type

### 2.4 Required Improvements

#### 2.4.1 AST Layer

**No structural changes needed** - The AST already has full support for option/result flags and type wrapping.

#### 2.4.2 WASM Backend Type Handling

**Location**: `vlib/v/gen/wasm/ops.v`, `gen.v`

1. **Update `get_wasm_type()`**:
   ```v
   pub fn (mut g Gen) get_wasm_type(typ_ ast.Type) wasm.ValType {
       typ := ast.mktyp(typ_)
       
       // Handle option/result types
       if typ.has_flag(.option) || typ.has_flag(.result) {
           // Option/Result types are always returned as pointer to struct
           return wasm.ValType.i32_t
       }
       
       // ... rest of existing logic
   }
   ```

2. **Update `is_pure_type()`**:
   ```v
   pub fn (g &Gen) is_pure_type(typ ast.Type) bool {
       // Option/Result types are NOT pure types
       if typ.has_flag(.option) || typ.has_flag(.result) {
           return false
       }
       // ... rest of existing logic
   }
   ```

#### 2.4.3 Function Return Types

**Location**: `vlib/v/gen/wasm/gen.v`, function `fn_decl()` (lines 176-268)

**Current Logic**:
- Lines 241-242: Error on option types
- Lines 260-261: Error on void option
- Lines 265-266: Error on result types

**Required Changes**:

1. **Option Return Types**:
   ```v
   if rt.has_flag(.option) {
       // Remove the error, instead:
       // 1. The return type becomes a pointer to Option struct
       // 2. Add i32_t to retl (pointer to option)
       // 3. Track that function returns option in g.ret_types
       retl << .i32_t  // pointer to Option_T struct
   }
   ```

2. **Result Return Types**:
   ```v
   if rt.has_flag(.result) {
       // Similar to option:
       // 1. Return pointer to _result struct
       // 2. Track error handling requirements
       retl << .i32_t  // pointer to _result struct
   }
   ```

3. **Void Option/Result**:
   ```v
   if rt.idx() == ast.void_type_idx {
       if rt.has_flag(.option) {
           // fn()? returns just error state
           retl << .i32_t  // u8 state or pointer to Option
       } else if rt.has_flag(.result) {
           // fn()! returns IError or nil
           retl << .i32_t  // pointer to IError
       }
   }
   ```

#### 2.4.4 Option/Result Creation and Unwrapping

**New Functions Needed** in `vlib/v/gen/wasm/gen.v`:

1. **Creating Option Values**:
   ```v
   fn (mut g Gen) create_option(inner_type ast.Type, has_value bool) {
       // Allocate Option_T struct on heap/stack
       // Set state field: 0 (ok), 2 (none)
       // If has_value, copy data after err field
       // Push pointer to stack
   }
   ```

2. **Creating Result Values**:
   ```v
   fn (mut g Gen) create_result(inner_type ast.Type, has_error bool, error_val ast.Expr) {
       // Allocate _result struct
       // Set is_error field
       // If error, set err field to IError pointer
       // Otherwise copy success data
       // Push pointer to stack
   }
   ```

3. **Unwrapping with `or` blocks**:
   ```v
   fn (mut g Gen) unwrap_option_or_result(node ast.OrExpr, typ ast.Type) {
       // Check state/is_error field
       // If error/none:
       //   - Execute or block
       //   - Handle propagation if `?` or `!`
       // If ok:
       //   - Load data from after err field
       //   - Continue execution
   }
   ```

#### 2.4.5 Memory Layout

**Option Type Layout**:
```
Offset | Field        | Size
-------|--------------|-------
0      | state (u8)   | 1 byte
1-7    | padding      | 7 bytes (alignment)
8      | err (IError) | 4 bytes (pointer)
12     | data (T)     | sizeof(T)
```

**Result Type Layout**:
```
Offset | Field          | Size
-------|----------------|-------
0      | is_error (bool)| 1 byte
1-7    | padding        | 7 bytes (alignment)
8      | err (IError)   | 4 bytes (pointer)
12     | data (T)       | sizeof(T)
```

**Implementation Requirements**:
- Use `g.pool.type_size()` to get size of wrapped type
- Allocate struct with: `base_size + wrapped_type_size`
- Use proper alignment (8 bytes for struct header)
- Access data at offset: `&option.err + sizeof(IError)`

#### 2.4.6 Error Propagation

**Handle `?` and `!` propagation operators**:

When a function call returns option/result and is followed by `?` or `!`:
1. Check the return value state
2. If error/none, return early from current function
3. If current function also returns option/result, propagate the error
4. Otherwise unwrap and continue

**Expression Handling**:
- `expr()?` - unwrap or propagate
- `expr()!` - unwrap or propagate  
- `expr() or { ... }` - unwrap or execute block

### 2.5 Builtin Support

**Location**: `vlib/builtin/wasm/`

1. **Error Handling**:
   - Ensure `IError` interface works in WASM
   - `error()` function for creating errors
   - `panic()` already exists, ensure it works with errors

2. **Helper Functions**:
   ```v
   // In vlib/builtin/wasm/option_result.v (new file)
   fn _option_none(data voidptr, mut option _option, size int)
   fn _option_ok(data voidptr, mut option _option, size int)
   fn _result_ok(data voidptr, mut res _result, size int)
   ```

## 3. Implementation Priorities

### Phase 1: Basic Dynamic Array Support
1. Add `ast.Array` case to `get_wasm_type()`
2. Implement array allocation calling `__new_array()`
3. Implement array indexing with bounds checking
4. Add array field accessors (len, cap, data)

### Phase 2: Array Operations
1. Implement `<<` (append) operator
2. Implement array methods: push, pop
3. Add array growth/reallocation
4. Implement slicing operations

### Phase 3: Basic Option/Result Support
1. Remove errors for option/result returns
2. Update type handling for option/result flags
3. Implement option/result struct allocation
4. Basic unwrapping with `or` blocks

### Phase 4: Complete Option/Result Support
1. Error propagation with `?` and `!`
2. Option/Result in function parameters
3. Nested option/result types
4. Option/Result arrays and complex types

### Phase 5: Advanced Features
1. Array higher-order functions (map, filter, etc.)
2. Array sorting and searching
3. Multi-dimensional arrays
4. Performance optimizations

## 4. Testing Requirements

### 4.1 Dynamic Array Tests

Create `vlib/v/gen/wasm/tests/dynamic_arrays.vv`:
```v
fn test_array_creation() {
    a := []int{}
    assert a.len == 0
    
    b := [1, 2, 3]
    assert b.len == 3
    assert b[0] == 1
}

fn test_array_append() {
    mut a := []int{}
    a << 1
    a << 2
    assert a.len == 2
    assert a[1] == 2
}

fn test_array_methods() {
    mut a := [1, 2, 3]
    a.delete(1)
    assert a == [1, 3]
}
```

### 4.2 Option/Result Tests

Create `vlib/v/gen/wasm/tests/option_result.vv`:
```v
fn return_option() ?int {
    return 42
}

fn return_none() ?int {
    return none
}

fn return_result() !int {
    return 42
}

fn return_error() !int {
    return error('test error')
}

fn test_options() {
    a := return_option() or { 0 }
    assert a == 42
    
    b := return_none() or { 100 }
    assert b == 100
}

fn test_results() {
    a := return_result() or { panic('should not error') }
    assert a == 42
    
    b := return_error() or { 999 }
    assert b == 999
}
```

## 5. Documentation Updates

### 5.1 Files to Update

1. **vlib/wasm/README.md**:
   - Add section on dynamic arrays
   - Add section on option/result types
   - Update limitations section

2. **ROADMAP.md** (if applicable):
   - Mark WASM backend improvements
   - Note option/result support for WASM

3. **doc/docs.md**:
   - Update WASM backend documentation
   - List supported features

### 5.2 Code Examples

Add working examples:
- `examples/wasm/dynamic_arrays.v`
- `examples/wasm/error_handling.v`
- `examples/wasm_codegen/arrays_dynamic.v`
- `examples/wasm_codegen/option_result.v`

## 6. Potential Challenges

### 6.1 Memory Management
- WASM has linear memory model
- Need to manage heap carefully
- Array growth requires reallocation
- May need custom allocator improvements

### 6.2 Performance
- Bounds checking overhead
- Memory copying during reallocation
- Consider `[direct_array_access]` attribute for performance-critical code

### 6.3 Interfacing with JavaScript
- Arrays may need special handling when calling JS functions
- Option/Result types need JavaScript-friendly representation
- Consider serialization requirements

### 6.4 Size Optimization
- Option/Result add memory overhead
- May need compile-time optimization to eliminate wrapping where possible
- Consider monomorphization for generic array functions

## 7. Related Work

### 7.1 Reference Implementations
- Study C backend: `vlib/v/gen/c/array.v`
- Study C backend: `vlib/v/gen/c/fn.v` for option/result handling
- Review JavaScript backend for dynamic array patterns

### 7.2 Upstream Dependencies
- Ensure `vlib/builtin/array.v` functions work in WASM context
- Verify `vlib/builtin/chan_option_result.v` compatibility
- Check that all required builtins are available

## 8. Success Criteria

The implementation will be considered complete when:

1. ✅ All existing WASM tests continue to pass
2. ✅ New dynamic array tests pass
3. ✅ New option/result tests pass
4. ✅ Can compile and run real-world programs using arrays and error handling
5. ✅ No regression in code size or performance for existing features
6. ✅ Documentation is complete and accurate
7. ✅ Examples demonstrate all new features

## Summary

This comprehensive improvement plan covers all aspects needed to bring dynamic array and option/result support to the V WASM backend. The implementation should be done incrementally, with thorough testing at each phase, to ensure stability and maintainability of the codebase.
