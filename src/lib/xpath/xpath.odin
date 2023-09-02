package xpath

import "hlc:xml"

Result :: union {
  int,
  string,
  XMLNodeCollection,
  }

XMLNodeCollection :: xml.XMLNodeCollection

run_query :: proc(nc: XMLNodeCollection, xpath_query: string) -> Result {

  return 1
}
