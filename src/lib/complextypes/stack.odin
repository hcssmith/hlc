package complextypes

import "core:fmt"

Stack :: struct($T: typeid) {
  _queue :[dynamic]T,
}

make_stack :: proc($T: typeid) -> ^Stack(T) {
  s:=new(Stack(T), context.allocator)
  s._queue = make([dynamic]T)
  return s
}

Pop :: proc($T: typeid, s: ^Stack(T)) -> Maybe(T) {
  l := len(s._queue)
  if l == 0 {
    return nil
  } 
  r := s._queue[l - 1]
  arr:= make([]T, l-1)
  copy_slice(arr, s._queue[0:l-1])
  s._queue = make([dynamic]T)
  x:=0
  for {
    if x >= len(arr) { break }
    append(&s._queue, arr[x])
    x+=1
  }
  return r
}

Push :: proc($T: typeid, s:^Stack(T), item:T) {
  append(&s._queue, item)
}

Skim :: proc($T: typeid, s:^Stack(T)) -> Maybe(T) {
  l := len(s._queue)
  if l == 0 {
    return nil
  } 
  return s._queue[l - 1]
}
