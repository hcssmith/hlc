package buffers

import "core:unicode/utf8"

@(private)
RuneBuffer :: struct {
  _buf: [dynamic]rune,
  Add: proc(^RuneBuffer, rune),
  Clear: proc(^RuneBuffer),
  ToString: proc(^RuneBuffer) -> string,
}

make_runebuffer :: proc() -> RuneBuffer {
  buf: RuneBuffer
  buf._buf = make([dynamic]rune)
  buf.Add = add
  buf.Clear = clear
  buf.ToString = to_string
  return buf
}

@(private)
add :: proc(buf: ^RuneBuffer, r: rune) {
  append(&buf._buf, r)
}

@(private)
clear :: proc(buf: ^RuneBuffer) {
  buf._buf = make([dynamic]rune)
}

@(private)
to_string :: proc(buf: ^RuneBuffer) -> string {
  r: =make([]rune, len(buf._buf))
  copy(r, buf._buf[:])
  return utf8.runes_to_string(r)
}
