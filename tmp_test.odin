package test_runner_tmp
import  "hlc:test"
import  "tests:buffers"
main :: proc() {
t:=test.new_t()
test.register_test(t,buffers.test_buffer_add,"test_buffer_add",9,"/home/hcssmith/Documents/GitHub/hlc/src/tests/buffers/test_buffers.odin")
test.runner(t)
}
