package test_buffers

import "hlc:test"
import b "hlc:buffers"

print_test_info :: test.print_test_info
T               :: test.T

test_buffer_add :: proc(t:^T) {
  buf := b.make_runebuffer()

  buf->Add('A')

  test.expect(t, buf._buf[0] == 'A', "Should be the rune: A")
}
