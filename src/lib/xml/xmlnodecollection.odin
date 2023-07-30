package xml

import "core:strings"
import "core:fmt"
import "hlc:util/ustring"
import "hlc:tokeniser"

XMLNodeCollection :: struct {
  LatestNodeID: NodeID,
  Nodes: [dynamic]^XMLNode,
  RootNode: NodeID,
  //interface
  add_node: proc(^XMLNodeCollection, ^XMLNode),
  get_node_by_id: proc(^XMLNodeCollection, NodeID) -> ^XMLNode,
  pretty_print: proc(^XMLNodeCollection),
  parse_string: proc(^XMLNodeCollection, string),
  }

make_node_collection :: proc() -> XMLNodeCollection {
  nc:XMLNodeCollection
  nc.LatestNodeID = -1
  nc.Nodes = make([dynamic]^XMLNode)
  nc.add_node = add_node
  nc.pretty_print = pretty_print
  nc.get_node_by_id = get_node_by_id
  nc.parse_string = parse_string
  return nc
  }

add_node :: proc(nc: ^XMLNodeCollection, node: ^XMLNode) {
  nc.LatestNodeID += 1
  node.ID = nc.LatestNodeID
  append(&nc.Nodes, node)
}

get_node_by_id :: proc(self: ^XMLNodeCollection, id:NodeID) -> ^XMLNode {
  for i in self.Nodes {
    if  i.ID == id {
      return i
    }
  }
  return nil 
}

opening_tag :: proc(nc: ^XMLNodeCollection, node:^XMLNode) -> string {
  parent_node := nc->get_node_by_id(node.ParentID)
  tb := strings.builder_make()
  strings.write_string(&tb, "<")
  // tag name
  if node.Namespace != "" {
    strings.write_string(&tb, node.Namespace)
    strings.write_string(&tb, ":")
  }
  strings.write_string(&tb, node.Name)

  //namespace declarations
  for k, v in node.NamespacesInScope {
    if parent_node != nil {
      if parent_node.NamespacesInScope[k] == v { continue }
    }
    if k == DEFAULTNAMESPACE {
      fmt.sbprintf(&tb, " xmlns=\"{0}\"", v)
    } else {
      fmt.sbprintf(&tb, " xmlns:{0}=\"{1}\"", k, v)
    }
  }
  // attributes
  for attrid in node.Attributes {
    attr := nc->get_node_by_id(attrid)
    strings.write_string(&tb, " ")
    //namespace
    if attr.Namespace != "" {
      strings.write_string(&tb, attr.Namespace)
      strings.write_string(&tb, ":")
    }
    fmt.sbprintf(&tb, "{0}=\"{1}\"", attr.Name, attr.Text)
    }
  strings.write_string(&tb, ">")
  return strings.to_string(tb)
}

node_to_text :: proc(nc: ^XMLNodeCollection, nodeid: int, indent_level: int = 0) -> string {
  indent := ustring.repeat_string("\t", indent_level)
  sb:=strings.builder_make()
  node := nc->get_node_by_id(nodeid)
  fmt.sbprintf(&sb, "{0}{1}\n", indent, opening_tag(nc, node))
  if node.Text != "" {
    fmt.sbprintf(&sb, "{0}{1}",indent, node.Text)
  } else {
    for child in node.Children {
      strings.write_string(&sb, node_to_text(nc, child, indent_level +1))
    }
  }
  fmt.sbprintf(&sb, "{0}<", indent)
  if node.Namespace != "" {
    fmt.sbprintf(&sb, "{0}:", node.Namespace)
  }
  fmt.sbprintf(&sb, "{0}>\n", node.Name)
  return strings.to_string(sb)
}

pretty_print :: proc(self: ^XMLNodeCollection) {

  fmt.printf("{0}\n", node_to_text(self, self.RootNode))
  }

KnownToken :: enum {
  OpenTag,
  CloseTag,
  CloseIndicator,
  Quote,
  DoubleQuote,
  Assign,
  CommentOpen,
  CommentClose,
}

parse_string :: proc(nc: ^XMLNodeCollection, xmlstring: string) {

  nc.Nodes = make([dynamic]^XMLNode)
  nc.LatestNodeID = -1
  nc.RootNode = -1

  token_map:map[string]KnownToken

  token_map["<"] = .OpenTag
  token_map["<!--"] = .CommentOpen
  token_map["-->"] = .CommentClose
  token_map[">"] = .CloseTag
  token_map["/"] = .CloseIndicator
  token_map["'"] = .Quote
  token_map["\""] = .DoubleQuote
  token_map["="] = .Assign


  tokens := tokeniser.tokeniser(token_map, xmlstring)
  fmt.printf("{0}", tokens)

  for token in tokens {


  }
  

}
