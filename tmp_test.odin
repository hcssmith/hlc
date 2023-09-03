package test_runner_tmp
import  "hlc:test"
import  "tests:buffers"
main :: proc() {
test.register_test(buffers.test_buffer_add)
}
