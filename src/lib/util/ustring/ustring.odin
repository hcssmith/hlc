package ustring

import "core:strings"

repeat_string :: proc(s: string, count:int) -> string {
  ib := strings.builder_make() 
  ic := count
  for {
    if  ic == 0 {break}
    strings.write_string(&ib, "\t")
    ic-=1
  }
  return strings.to_string(ib)
}
