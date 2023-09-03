package main

import "hlc:test"


main :: proc() {

  tc := test.make_test_collection()
  
  test.register_location(&tc, "./src/tests/buffers", "tests:buffers")

  f := test.build_file(tc)

  test.print_file(f, "tmp_test.odin")
}

