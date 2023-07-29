package usage

import df "hlc:datafile"
import ct "hlc:complextypes"
import bf "hlc:buffers"
import tk "hlc:tokeniser"
import xm "hlc:xml"

import "core:fmt"

main :: proc() {

  nc := xm.make_node_collection()

  nc->parse_string("<!-- this is a comment --><a href=\"https://google.com\">Google</a>")
}
