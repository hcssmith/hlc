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

  f: test.File
  ci: test.Import
  ci.Library = "fmt"
  ci.Collection = "core"
  ci.Id = 0

  fn:test.Function
  fn.Name = "printf"
  fn.Pkg = 0

  fna:test.Arg

  fna.Value = "\"test\\n\""

  append(&fn.Args, fna)
  append(&f.Imports, ci)
  append(&f.TestFunctions, fn)


  test.print_file(f, "tmp_test.odin")
  

}

