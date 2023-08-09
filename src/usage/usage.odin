package usage

import df "hlc:datafile"
import ct "hlc:complextypes"
import bf "hlc:buffers"
import tk "hlc:tokeniser"
import xm "hlc:xml"

import "core:fmt"

main :: proc() {

  nc := xm.make_node_collection()
  s:string = "<!-- this is a comment --><a href=\"https://google.com\">Google</a>"
  s2:string = "<ns:self-close-test type=\"a\" />"
  
  fmt.printf("{0}\n", s)
  nc->parse_string(s)
  

  fmt.printf("{0}\n", s2)
  nc->parse_string(s2)
}
