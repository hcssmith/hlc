package usage

import df "hlc:datafile"
import ct "hlc:complextypes"
import bf "hlc:buffers"
import tk "hlc:tokeniser"
import xm "hlc:xml"

import "core:fmt"
import "core:log"




main :: proc() {

  context.logger = log.create_console_logger()

  nc := xm.make_node_collection()
  s:string = "<?xml version=\"1\" encoding=\"UTF-8\"?><?xsl-stylesheet href=\"http://hcssmith/com/xsl/article\"?><article xmlns=\"https://hcssmith.com/ns/article\"><title>Some Article</title><blurb>This is some text.</blurb></article>"
  
  fmt.printf("{0}\n", s)
  nc->parse_string(s)
}
