package xml

import "core:fmt"
import "core:strings"


NodeType :: enum {
  Text,
  Attr,
  Elem,
  }

NodeID :: int


XMLNode :: struct {
  Type: NodeType,
  ID: NodeID,
  ParentID: NodeID,
  Attributes: [dynamic]NodeID,
  Children: [dynamic]NodeID,
  NamespacesInScope: map[string]string,
  Text: string,
  Name: string,
  Namespace: string,
  // interface
  to_string: proc(^XMLNode) -> string,
  set_text: proc(^XMLNode, string),
  add_child: proc(^XMLNode, ^XMLNode),
  add_attr: proc(^XMLNode, ^XMLNode),
  }



new_node :: proc(type: NodeType, name: string, namespace: string = "") -> ^XMLNode { 
  node := new(XMLNode)
  node.Children = make([dynamic]NodeID)
  node.Attributes = make([dynamic]NodeID)
  node.NamespacesInScope = make(map[string]string)
  node.ID = -1
  node.ParentID = -1
  node.Type = type
  if type == .Attr || type == .Elem {
    node.Name = name
    node.Namespace = namespace
  } else { 
    node.Text = name
  }
  node.to_string = to_string
  node.add_child = add_child
  node.add_attr = add_attr
  node.set_text = set_text
  return node
}

set_text :: proc(self: ^XMLNode, text:string) {
  self.Text = text
  self.Children = make([dynamic]NodeID)
}

add_child :: proc(self: ^XMLNode, child:^XMLNode) {
  if self.ID == -1 || child.ID == -1 {
    fmt.printf("Node should be in XMLNodeCollection before a relationship can be added")
    return
    }
  append(&self.Children, child.ID) 
  child.ParentID = self.ID
  }

add_attr :: proc(self: ^XMLNode, child:^XMLNode) {
  if self.ID == -1 || child.ID == -1 {
    fmt.printf("Node should be in XMLNodeCollection before a relationship can be added")
    return
    }
  append(&self.Attributes, child.ID) 
  child.ParentID = self.ID
  }

to_string :: proc(self: ^XMLNode) -> string {
  sb:=strings.builder_make()

  fmt.sbprintf(&sb, "Node:\n")
  fmt.sbprintf(&sb, "\tType: {0}\n", self.Type)
  fmt.sbprintf(&sb, "\tID: {0}\n", self.ID)
  fmt.sbprintf(&sb, "\tParent ID: {0}\n", self.ParentID)
  fmt.sbprintf(&sb, "\tNamespacesInScope: {0}\n", self.NamespacesInScope)
  fmt.sbprintf(&sb, "\tAttributes: {0}\n", self.Attributes)
  fmt.sbprintf(&sb, "\tChildren: {0}\n", self.Children)
  fmt.sbprintf(&sb, "\tText: {0}\n", self.Text)
  fmt.sbprintf(&sb, "\tName: {0}\n", self.Name)
  fmt.sbprintf(&sb, "\tNamespace: {0}\n", self.Namespace)

  return strings.to_string(sb)
}
