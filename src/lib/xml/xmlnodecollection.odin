package xml

import "core:strings"
import "core:fmt"

XMLNodeCollection :: struct {
  LatestNodeID: NodeID,
  Nodes: [dynamic]^XMLNode,
  RootNode: NodeID,
  //interface
  add_node: proc(^XMLNodeCollection, ^XMLNode),
  get_node_by_id: proc(^XMLNodeCollection, NodeID) -> ^XMLNode,
  pretty_print: proc(^XMLNodeCollection),
  }

make_node_collection :: proc() -> XMLNodeCollection {
  nc:XMLNodeCollection
  nc.LatestNodeID = -1
  nc.Nodes = make([dynamic]^XMLNode)
  nc.add_node = add_node
  nc.pretty_print = pretty_print
  nc.get_node_by_id = get_node_by_id
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
    strings.write_string(&tb, " ")
    strings.write_string(&tb, "xmlns:")
    strings.write_string(&tb, k)
    strings.write_string(&tb, "=\"")
    strings.write_string(&tb, v)
    strings.write_string(&tb, "\"")
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
    strings.write_string(&tb, attr.Name)
    strings.write_string(&tb, "=\"")
    strings.write_string(&tb, attr.Text)
    strings.write_string(&tb, "\"")
    }
  strings.write_string(&tb, ">")
  return strings.to_string(tb)
}

pretty_print :: proc(self: ^XMLNodeCollection) {
  basenode := self->get_node_by_id(self.RootNode)

  fmt.printf("{0}\n", opening_tag(self, basenode))
  }

