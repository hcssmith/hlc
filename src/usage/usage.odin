package usage

import df "hlc:datafile"
import ct "hlc:complextypes"
import bf "hlc:buffers"
import tk "hlc:tokeniser"
import xm "hlc:xml"

import "core:fmt"

main :: proc() {

  nc := xm.make_node_collection()
  s2:string = "<?xml version=\"1.0\"?><ns:self-close-test type=\"a\" />"
  
  

  fmt.printf("{0}\n", s2)
  nc->parse_string(s2)
}
