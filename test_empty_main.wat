(module
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (param i32)))
  (type (;2;) (func (result i32)))
  (type (;3;) (func (param i32 i32 i32) (result i32)))
  (type (;4;) (func (param i32 i32 i32)))
  (type (;5;) (func (param i32 i32)))
  (type (;6;) (func (param i32 i64)))
  (type (;7;) (func (param i32 i32 i32 i32) (result i32)))
  (type (;8;) (func))
  (import "wasi_snapshot_preview1" "fd_write" (func (;0;) (type 7)))
  (import "wasi_snapshot_preview1" "proc_exit" (func (;1;) (type 1)))
  (func (;2;) (type 0) (param i32) (result i32)
    (local i32 i32)
    global.get 1
    i32.const 8
    i32.sub
    local.tee 1
    global.set 1
    block (result i32)  ;; label = @1
      local.get 0
      i32.const 0
      i32.le_s
      if  ;; label = @2
        local.get 1
        i32.const 17424
        i32.store
        local.get 1
        i32.const 14
        i32.store offset=4
        local.get 1
        call 17
        unreachable
      end
      global.get 0
      local.set 2
      global.get 0
      local.get 0
      i32.add
      global.set 0
      local.get 2
      br 0 (;@1;)
    end
    global.get 1
    i32.const 8
    i32.add
    global.set 1)
  (func (;3;) (type 1) (param i32)
    (local i32)
    block  ;; label = @1
      local.get 0
      drop
    end)
  (func (;4;) (type 2) (result i32)
    (local i32)
    block (result i32)  ;; label = @1
      i32.const 0
      local.set 0
      global.get 2
      local.set 0
      local.get 0
      br 0 (;@1;)
    end)
  (func (;5;) (type 2) (result i32)
    (local i32)
    block (result i32)  ;; label = @1
      i32.const 0
      local.set 0
      memory.size
      local.set 0
      local.get 0
      br 0 (;@1;)
    end)
  (func (;6;) (type 0) (param i32) (result i32)
    (local i32)
    block (result i32)  ;; label = @1
      i32.const 0
      local.set 1
      local.get 0
      memory.grow
      local.set 1
      local.get 1
      br 0 (;@1;)
    end)
  (func (;7;) (type 0) (param i32) (result i32)
    (local i32 i32)
    global.get 1
    i32.const 8
    i32.sub
    local.tee 1
    global.set 1
    block (result i32)  ;; label = @1
      local.get 0
      i32.const 0
      i32.le_s
      if  ;; label = @2
        local.get 1
        i32.const 17438
        i32.store
        local.get 1
        i32.const 14
        i32.store offset=4
        local.get 1
        call 17
        unreachable
      end
      local.get 0
      call 2
      local.set 2
      local.get 2
      i32.const 0
      local.get 0
      memory.fill
      local.get 2
      br 0 (;@1;)
    end
    global.get 1
    i32.const 8
    i32.add
    global.set 1)
  (func (;8;) (type 0) (param i32) (result i32)
    block (result i32)  ;; label = @1
      local.get 0
      i32.const 0
      i32.eq
      br 0 (;@1;)
    end)
  (func (;9;) (type 3) (param i32 i32 i32) (result i32)
    block (result i32)  ;; label = @1
      local.get 0
      local.get 1
      local.get 2
      memory.copy
      local.get 0
      br 0 (;@1;)
    end)
  (func (;10;) (type 3) (param i32 i32 i32) (result i32)
    block (result i32)  ;; label = @1
      local.get 0
      local.get 1
      local.get 2
      memory.copy
      local.get 0
      br 0 (;@1;)
    end)
  (func (;11;) (type 3) (param i32 i32 i32) (result i32)
    block (result i32)  ;; label = @1
      local.get 0
      local.get 1
      local.get 2
      memory.fill
      local.get 0
      br 0 (;@1;)
    end)
  (func (;12;) (type 1) (param i32)
    (local i32)
    global.get 1
    i32.const 8
    i32.sub
    local.set 1
    block  ;; label = @1
      local.get 1
      local.get 0
      i32.load
      i32.store
      local.get 1
      local.get 0
      i32.load offset=4
      i32.store offset=4
      i32.const 1
      local.get 1
      i32.const 1
      i32.const 0
      call 0
      drop
    end)
  (func (;13;) (type 1) (param i32)
    (local i32)
    global.get 1
    i32.const 16
    i32.sub
    local.set 1
    block  ;; label = @1
      local.get 1
      local.get 0
      i32.load
      i32.store
      local.get 1
      local.get 0
      i32.load offset=4
      i32.store offset=4
      local.get 1
      i32.const 17452
      i32.store offset=8
      local.get 1
      i32.const 1
      i32.store offset=12
      i32.const 1
      local.get 1
      i32.const 0
      i32.const 8
      i32.mul
      i32.add
      i32.const 2
      i32.const 0
      call 0
      drop
    end)
  (func (;14;) (type 1) (param i32)
    (local i32)
    global.get 1
    i32.const 8
    i32.sub
    local.set 1
    block  ;; label = @1
      local.get 1
      local.get 0
      i32.load
      i32.store
      local.get 1
      local.get 0
      i32.load offset=4
      i32.store offset=4
      i32.const 2
      local.get 1
      i32.const 1
      i32.const 0
      call 0
      drop
    end)
  (func (;15;) (type 1) (param i32)
    (local i32)
    global.get 1
    i32.const 16
    i32.sub
    local.set 1
    block  ;; label = @1
      local.get 1
      local.get 0
      i32.load
      i32.store
      local.get 1
      local.get 0
      i32.load offset=4
      i32.store offset=4
      local.get 1
      i32.const 17452
      i32.store offset=8
      local.get 1
      i32.const 1
      i32.store offset=12
      i32.const 2
      local.get 1
      i32.const 0
      i32.const 8
      i32.mul
      i32.add
      i32.const 2
      i32.const 0
      call 0
      drop
    end)
  (func (;16;) (type 1) (param i32)
    block  ;; label = @1
      local.get 0
      call 1
      unreachable
    end)
  (func (;17;) (type 1) (param i32)
    (local i32)
    global.get 1
    i32.const 8
    i32.sub
    local.tee 1
    global.set 1
    block  ;; label = @1
      local.get 1
      i32.const 17453
      i32.store
      local.get 1
      i32.const 9
      i32.store offset=4
      local.get 1
      call 14
      local.get 0
      call 15
      i32.const 1
      call 16
      unreachable
    end
    global.get 1
    i32.const 8
    i32.add
    global.set 1)
  (func (;18;) (type 4) (param i32 i32 i32)
    (local i64 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32)
    block  ;; label = @1
      local.get 1
      i64.extend_i32_s
      local.set 3
      i32.const 0
      local.set 4
      local.get 3
      i64.const 0
      i64.eq
      if  ;; label = @2
        local.get 0
        i32.const 17462
        i32.store
        local.get 0
        i32.const 1
        i32.store offset=4
        br 1 (;@1;)
      end
      i32.const 0
      local.set 5
      local.get 3
      i64.const 0
      i64.lt_s
      if  ;; label = @2
        i64.const 0
        local.get 3
        i64.sub
        local.set 3
        i32.const 1
        local.set 5
      end
      local.get 2
      local.set 6
      local.get 2
      i32.const 1
      i32.add
      call 2
      local.set 7
      i32.const 0
      local.get 7
      local.get 6
      i32.add
      local.set 8
      local.set 9
      local.get 8
      local.get 9
      i32.store8
      local.get 6
      i32.const 1
      i32.sub
      local.set 6
      block  ;; label = @2
        loop  ;; label = @3
          local.get 3
          i64.const 0
          i64.gt_s
          i32.eqz
          br_if 1 (;@2;)
          local.get 3
          i64.const 100
          i64.div_s
          i32.wrap_i64
          local.set 10
          local.get 3
          i32.wrap_i64
          local.get 10
          i32.const 100
          i32.mul
          i32.sub
          i32.const 1
          i32.shl
          local.set 4
          local.get 10
          i64.extend_i32_s
          local.set 3
          global.get 3
          i32.load
          local.get 4
          i32.add
          i32.load8_u
          local.get 7
          local.get 6
          i32.add
          local.set 11
          local.set 12
          local.get 11
          local.get 12
          i32.store8
          local.get 6
          i32.const 1
          i32.sub
          local.set 6
          local.get 4
          i32.const 1
          i32.add
          local.set 4
          global.get 3
          i32.load
          local.get 4
          i32.add
          i32.load8_u
          local.get 7
          local.get 6
          i32.add
          local.set 13
          local.set 14
          local.get 13
          local.get 14
          i32.store8
          local.get 6
          i32.const 1
          i32.sub
          local.set 6
          br 0 (;@3;)
        end
      end
      local.get 6
      i32.const 1
      i32.add
      local.set 6
      local.get 4
      i32.const 20
      i32.lt_s
      if  ;; label = @2
        local.get 6
        i32.const 1
        i32.add
        local.set 6
      end
      local.get 5
      if  ;; label = @2
        local.get 6
        i32.const 1
        i32.sub
        local.set 6
        i32.const 45
        local.get 7
        local.get 6
        i32.add
        local.set 15
        local.set 16
        local.get 15
        local.get 16
        i32.store8
      end
      local.get 2
      local.get 6
      i32.sub
      local.set 17
      local.get 7
      local.get 7
      local.get 6
      i32.add
      local.get 17
      i32.const 1
      i32.add
      call 10
      drop
      local.get 0
      local.get 7
      local.get 17
      call 29
      br 0 (;@1;)
    end)
  (func (;19;) (type 5) (param i32 i32)
    block  ;; label = @1
      local.get 0
      local.get 1
      i32.const 5
      call 18
      br 0 (;@1;)
    end)
  (func (;20;) (type 5) (param i32 i32)
    block  ;; label = @1
      local.get 0
      local.get 1
      i32.const 5
      call 18
      br 0 (;@1;)
    end)
  (func (;21;) (type 5) (param i32 i32)
    block  ;; label = @1
      local.get 0
      local.get 1
      i32.const 7
      call 18
      br 0 (;@1;)
    end)
  (func (;22;) (type 5) (param i32 i32)
    block  ;; label = @1
      local.get 0
      local.get 1
      i32.const 7
      call 18
      br 0 (;@1;)
    end)
  (func (;23;) (type 5) (param i32 i32)
    block  ;; label = @1
      local.get 0
      local.get 1
      i32.const 12
      call 18
      br 0 (;@1;)
    end)
  (func (;24;) (type 5) (param i32 i32)
    (local i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32)
    block  ;; label = @1
      local.get 1
      local.set 2
      i32.const 0
      local.set 3
      local.get 2
      i32.const 0
      i32.eq
      if  ;; label = @2
        local.get 0
        i32.const 17462
        i32.store
        local.get 0
        i32.const 1
        i32.store offset=4
        br 1 (;@1;)
      end
      i32.const 12
      local.set 4
      local.get 4
      i32.const 1
      i32.add
      call 2
      local.set 5
      local.get 4
      local.set 6
      i32.const 0
      local.get 5
      local.get 6
      i32.add
      local.set 7
      local.set 8
      local.get 7
      local.get 8
      i32.store8
      local.get 6
      i32.const 1
      i32.sub
      local.set 6
      block  ;; label = @2
        loop  ;; label = @3
          local.get 2
          i32.const 0
          i32.gt_u
          i32.eqz
          br_if 1 (;@2;)
          local.get 2
          i32.const 100
          i32.div_u
          local.set 9
          local.get 2
          local.get 9
          i32.const 100
          i32.mul
          i32.sub
          i32.const 1
          i32.shl
          local.set 3
          local.get 9
          local.set 2
          global.get 3
          i32.load
          local.get 3
          i32.add
          i32.load8_u
          local.get 5
          local.get 6
          i32.add
          local.set 10
          local.set 11
          local.get 10
          local.get 11
          i32.store8
          local.get 6
          i32.const 1
          i32.sub
          local.set 6
          local.get 3
          i32.const 1
          i32.add
          local.set 3
          global.get 3
          i32.load
          local.get 3
          i32.add
          i32.load8_u
          local.get 5
          local.get 6
          i32.add
          local.set 12
          local.set 13
          local.get 12
          local.get 13
          i32.store8
          local.get 6
          i32.const 1
          i32.sub
          local.set 6
          br 0 (;@3;)
        end
      end
      local.get 6
      i32.const 1
      i32.add
      local.set 6
      local.get 3
      i32.const 20
      i32.lt_u
      if  ;; label = @2
        local.get 6
        i32.const 1
        i32.add
        local.set 6
      end
      local.get 4
      local.get 6
      i32.sub
      local.set 14
      local.get 5
      local.get 5
      local.get 6
      i32.add
      local.get 14
      i32.const 1
      i32.add
      call 10
      drop
      local.get 0
      local.get 5
      local.get 14
      call 29
      br 0 (;@1;)
    end)
  (func (;25;) (type 6) (param i32 i64)
    block  ;; label = @1
      local.get 0
      local.get 1
      call 26
      br 0 (;@1;)
    end)
  (func (;26;) (type 6) (param i32 i64)
    (local i64 i64 i32 i32 i32 i32 i32 i32 i64 i32 i32 i32 i32 i32 i32 i32)
    block  ;; label = @1
      local.get 1
      local.set 2
      i64.const 0
      local.set 3
      local.get 2
      i64.const 0
      i64.eq
      if  ;; label = @2
        local.get 0
        i32.const 17462
        i32.store
        local.get 0
        i32.const 1
        i32.store offset=4
        br 1 (;@1;)
      else
        local.get 2
        global.get 4
        i64.eq
        if  ;; label = @3
          local.get 0
          i32.const 17672
          i32.store
          local.get 0
          i32.const 20
          i32.store offset=4
          br 2 (;@1;)
        end
      end
      i32.const 20
      local.set 4
      local.get 4
      i32.const 1
      i32.add
      call 2
      local.set 5
      i32.const 0
      local.set 6
      local.get 2
      i64.const 0
      i64.lt_s
      if  ;; label = @2
        i64.const 0
        local.get 2
        i64.sub
        local.set 2
        i32.const 1
        local.set 6
      end
      local.get 4
      local.set 7
      i32.const 0
      local.get 5
      local.get 7
      i32.add
      local.set 8
      local.set 9
      local.get 8
      local.get 9
      i32.store8
      local.get 7
      i32.const 1
      i32.sub
      local.set 7
      block  ;; label = @2
        loop  ;; label = @3
          local.get 2
          i64.const 0
          i64.gt_s
          i32.eqz
          br_if 1 (;@2;)
          local.get 2
          i64.const 100
          i64.div_s
          local.set 10
          local.get 2
          local.get 10
          i64.const 100
          i64.mul
          i64.sub
          i32.wrap_i64
          i64.const 1
          i32.wrap_i64
          i32.shl
          i64.extend_i32_u
          local.set 3
          local.get 10
          local.set 2
          global.get 3
          i32.load
          local.get 3
          i32.wrap_i64
          i32.add
          i32.load8_u
          local.get 5
          local.get 7
          i32.add
          local.set 11
          local.set 12
          local.get 11
          local.get 12
          i32.store8
          local.get 7
          i32.const 1
          i32.sub
          local.set 7
          local.get 3
          i64.const 1
          i64.add
          local.set 3
          global.get 3
          i32.load
          local.get 3
          i32.wrap_i64
          i32.add
          i32.load8_u
          local.get 5
          local.get 7
          i32.add
          local.set 13
          local.set 14
          local.get 13
          local.get 14
          i32.store8
          local.get 7
          i32.const 1
          i32.sub
          local.set 7
          br 0 (;@3;)
        end
      end
      local.get 7
      i32.const 1
      i32.add
      local.set 7
      local.get 3
      i64.const 20
      i64.lt_s
      if  ;; label = @2
        local.get 7
        i32.const 1
        i32.add
        local.set 7
      end
      local.get 6
      if  ;; label = @2
        local.get 7
        i32.const 1
        i32.sub
        local.set 7
        i32.const 45
        local.get 5
        local.get 7
        i32.add
        local.set 15
        local.set 16
        local.get 15
        local.get 16
        i32.store8
      end
      local.get 4
      local.get 7
      i32.sub
      local.set 17
      local.get 5
      local.get 5
      local.get 7
      i32.add
      local.get 17
      i32.const 1
      i32.add
      call 10
      drop
      local.get 0
      local.get 5
      local.get 17
      call 29
      br 0 (;@1;)
    end)
  (func (;27;) (type 6) (param i32 i64)
    (local i64 i64 i32 i32 i32 i32 i32 i64 i32 i32 i32 i32 i32)
    block  ;; label = @1
      local.get 1
      local.set 2
      i64.const 0
      local.set 3
      local.get 2
      i64.const 0
      i64.eq
      if  ;; label = @2
        local.get 0
        i32.const 17462
        i32.store
        local.get 0
        i32.const 1
        i32.store offset=4
        br 1 (;@1;)
      end
      i32.const 20
      local.set 4
      local.get 4
      i32.const 1
      i32.add
      call 2
      local.set 5
      local.get 4
      local.set 6
      i32.const 0
      local.get 5
      local.get 6
      i32.add
      local.set 7
      local.set 8
      local.get 7
      local.get 8
      i32.store8
      local.get 6
      i32.const 1
      i32.sub
      local.set 6
      block  ;; label = @2
        loop  ;; label = @3
          local.get 2
          i64.const 0
          i64.gt_u
          i32.eqz
          br_if 1 (;@2;)
          local.get 2
          i64.const 100
          i64.div_u
          local.set 9
          local.get 2
          local.get 9
          i64.const 100
          i64.mul
          i64.sub
          i64.const 1
          i64.shl
          local.set 3
          local.get 9
          local.set 2
          global.get 3
          i32.load
          local.get 3
          i32.wrap_i64
          i32.add
          i32.load8_u
          local.get 5
          local.get 6
          i32.add
          local.set 10
          local.set 11
          local.get 10
          local.get 11
          i32.store8
          local.get 6
          i32.const 1
          i32.sub
          local.set 6
          local.get 3
          i64.const 1
          i64.add
          local.set 3
          global.get 3
          i32.load
          local.get 3
          i32.wrap_i64
          i32.add
          i32.load8_u
          local.get 5
          local.get 6
          i32.add
          local.set 12
          local.set 13
          local.get 12
          local.get 13
          i32.store8
          local.get 6
          i32.const 1
          i32.sub
          local.set 6
          br 0 (;@3;)
        end
      end
      local.get 6
      i32.const 1
      i32.add
      local.set 6
      local.get 3
      i64.const 20
      i64.lt_u
      if  ;; label = @2
        local.get 6
        i32.const 1
        i32.add
        local.set 6
      end
      local.get 4
      local.get 6
      i32.sub
      local.set 14
      local.get 5
      local.get 5
      local.get 6
      i32.add
      local.get 14
      i32.const 1
      i32.add
      call 10
      drop
      local.get 0
      local.get 5
      local.get 14
      call 29
      br 0 (;@1;)
    end)
  (func (;28;) (type 5) (param i32 i32)
    block  ;; label = @1
      local.get 1
      if  ;; label = @2
        local.get 0
        i32.const 17692
        i32.store
        local.get 0
        i32.const 4
        i32.store offset=4
        br 1 (;@1;)
      end
      local.get 0
      i32.const 17696
      i32.store
      local.get 0
      i32.const 5
      i32.store offset=4
      br 0 (;@1;)
    end)
  (func (;29;) (type 4) (param i32 i32 i32)
    (local i32)
    global.get 1
    i32.const 8
    i32.sub
    local.tee 3
    global.set 1
    block  ;; label = @1
      local.get 1
      i32.const 0
      i32.eq
      if  ;; label = @2
        local.get 3
        i32.const 17701
        i32.store
        local.get 3
        i32.const 17
        i32.store offset=4
        local.get 3
        call 17
        unreachable
      end
      local.get 0
      local.get 1
      i32.store
      local.get 0
      local.get 2
      i32.store offset=4
      br 0 (;@1;)
    end
    global.get 1
    i32.const 8
    i32.add
    global.set 1)
  (func (;30;) (type 8))
  (func (;31;) (type 8)
    call 4
    global.set 0
    i32.const -2147483648
    i32.const 1
    i32.sub
    i64.extend_i32_u
    global.set 4)
  (func (;32;) (type 8)
    call 31
    call 30)
  (memory (;0;) 1)
  (global (;0;) (mut i32) (i32.const 0))
  (global (;1;) (mut i32) (i32.const 17408))
  (global (;2;) i32 (i32.const 17728))
  (global (;3;) i32 (i32.const 17664))
  (global (;4;) (mut i64) (i64.const 0))
  (export "_start" (func 32))
  (export "memory" (memory 0))
  (data (;0;) (i32.const 17424) "malloc(n <= 0)valloc(n <= 0)\0aV panic: 000102030405060708090011121314151617181910212223242526272829203132333435363738393041424344454647484940515253545556575859506162636465666768696071727374757677787970818283848586878889809192939495969798999\007D\00\00\c8\00\00\00-9223372036854775808truefalsetos(): nil string"))
