package main

import "hlc:test"
import "core:fmt"
import "tests:buffers"
import "core:odin/ast"
import "core:odin/parser"


main :: proc() {

  t := test.new_t()

  bpkg := "./src/tests/buffers"

  test.register_test(t, buffers.test_buffer_add, "test_buffer_add", bpkg)

  test.runner(t)


}

