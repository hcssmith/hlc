package test_buffers

import b "hlc:buffers"
import "core:testing"
import "core:fmt"
import "core:os"

TEST_count := 0
TEST_fail  := 0

main :: proc() {
  t := testing.T{}
  
  test_one(&t)

 
	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	} 
}

@test
test_one :: proc(t:^testing.T) {
  testing.expect(t, 2==2, "This is the message")
}
