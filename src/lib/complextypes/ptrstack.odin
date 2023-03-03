package complextypes

PtrStack :: struct($T: typeid) {
  _arr: [dynamic]^T,
}

make_ptr_stack :: proc($T: typeid) -> ^PtrStack(T) {
  p := new(PtrStack(T))
  return p
} 

ptr_stack_push :: proc($T: typeid, p: ^PtrStack(T), ptr: ^T ) {
  append(&p._arr, ptr)
}

ptr_stack_skim :: proc($T: typeid, p: ^PtrStack(T)) -> Maybe(^T) {
  l := len(p._arr)
  if l == nil {
    return nil
  }
  return p._arr[l-1]
}

ptr_stack_pop :: proc($T: typeid, s: ^PtrStack(T)) -> Maybe(^T) {
  l := len(s._queue)
  if l == 0 {
    return nil
  } 
  r := s._queue[l - 1]
  arr:= make([]T, l-1)
  copy_slice(arr, s._queue[0:l-1])
  s._queue = make([dynamic]^T)
  x:=0
  for {
    if x >= len(arr) { break }
    append(&s._queue, arr[x])
    x+=1
  }
  return r
}
