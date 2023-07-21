package usage

import df "hlc:datafile"
import ct "hlc:complextypes"
import bf "hlc:buffers"
import tk "hlc:tokeniser"
import xm "hlc:xml"

import "core:fmt"

main :: proc() {

  nc := xm.make_node_collection()

  n1 := xm.new_node(.Elem, "response", "response")
  n1.NamespacesInScope["response"] = "https://hcssmith.com/xsd/response"
  
  n2 := xm.new_node(.Elem, "header", "response")
  n2.NamespacesInScope["response"] = "https://hcssmith.com/xsd/response"

  nc->add_node(n1)
  nc->add_node(n2)

  n1->add_child(n2)

  nc->pretty_print()
}
