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
  if node.Name == COMMENT { return "<!--" }
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
  fmt.sbprintf(&sb, "{0}{1}", indent, opening_tag(nc, node))
  if node.Text != "" {
    fmt.sbprintf(&sb, "{0}",node.Text)
  } else {
    strings.write_string(&sb, "\n")
    for child in node.Children {
      strings.write_string(&sb, node_to_text(nc, child, indent_level +1))
    }
  }
  if node.Name == COMMENT {
    strings.write_string(&sb, "-->\n")
    return strings.to_string(sb)
  } else {
    fmt.sbprintf(&sb, "{0}<", indent)
  }
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
  NamespaceIndicator,
}

parse_string :: proc(nc: ^XMLNodeCollection, xmlstring: string) {

  nc.Nodes = make([dynamic]^XMLNode)
  nc.LatestNodeID = -1
  nc.RootNode = -1

  root_node := new_node(.Elem, ROOTNODE)

  nc->add_node(root_node)
  nc.RootNode = root_node.ID


  token_map:map[string]KnownToken

  token_map["<"] = .OpenTag
  token_map["<!--"] = .CommentOpen
  token_map["-->"] = .CommentClose
  token_map[">"] = .CloseTag
  token_map["/"] = .CloseIndicator
  token_map["'"] = .Quote
  token_map["\""] = .DoubleQuote
  token_map["="] = .Assign
  token_map[":"] = .NamespaceIndicator


  tokens := tokeniser.tokeniser(token_map, xmlstring)

  fmt.printf("{0}\n\n", tokens)

  cn := root_node
  parent := 0

  for x:=0; x<len(tokens); x+=1 {
    token := tokens[x]

    switch v in token {
      case KnownToken:
        switch v {
          case .CommentOpen:
            n := new_node(.Elem, COMMENT)
            s, i := advance_to_end_comment(&tokens, x, token_map)
            n->set_text(s)
            x = i
            nc->add_node(n)
            cn->add_child(n)
            continue
          case .CommentClose:
          case .OpenTag:
            if tok, ok := tokens[x+1].(KnownToken); ok {
              if tok == .CloseIndicator { break }
            }
            n, i, attrs := get_element_start_tag(&tokens, x, token_map)
            nc->add_node(n)
            cn->add_child(n)
            for attr in attrs {
              nc->add_node(attr)
              n->add_attr(attr)
            }
            x = i
          case .NamespaceIndicator:
          case .Assign:
          case .DoubleQuote:
          case .Quote:
          case .CloseIndicator:
          case .CloseTag:
            
        }
      case tokeniser.Identifier:
      case tokeniser.WhitespaceToken:

    }

  }
  nc->pretty_print()
}

get_element_start_tag :: proc(tokens: ^[dynamic]tokeniser.Token(KnownToken), index: int, token_map:map[string]KnownToken) -> (^XMLNode, int, [dynamic]^XMLNode) {
  attrs := make([dynamic]^XMLNode)

  n:=new_node(.Elem, "", "")

  if tok, ok := tokens[index+1].(tokeniser.Identifier); ok {
    n.Name = tok
  }

  if tok, ok:= tokens[index+2].(KnownToken); ok {
    if tok == .NamespaceIndicator && index + 3 < len(tokens) {
      if e, ok2 := tokens[index+3].(tokeniser.Identifier); ok2 {
        n.Namespace = n.Name
        n.Name = e
      }
    }
  }
  x := index+2 if n.Namespace == "" else index+4

  token_loop: for ;x<len(tokens);x+=1 {
    switch v in tokens[x] {
      case tokeniser.Identifier:
      case tokeniser.WhitespaceToken:
      case KnownToken:
        if v == .CloseTag {break token_loop}
    }

  }
  return n, x, nil
}


advance_to_end_comment :: proc(tokens: ^[dynamic]tokeniser.Token(KnownToken), index: int, token_map: map[string]KnownToken) -> (string, int) {
  sb := strings.builder_make()
  x:=index+1
  nesting_level := 0
  for ; x<len(tokens); x+=1 {
    switch v in tokens[x] {
      case KnownToken:
        if v == .CommentOpen {nesting_level+=1}
        if v == .CommentClose && nesting_level != 0 { nesting_level -= 1 }
        if v == .CommentClose && nesting_level == 0 {  
          return strings.to_string(sb), x
          }
        strings.write_string(&sb, token_to_string(v, token_map))
      case tokeniser.WhitespaceToken:
        switch v {
          case .NewLine:
            strings.write_string(&sb, "\n")
          case .Space:
            strings.write_string(&sb, " ")
          case .Tab:
            strings.write_string(&sb, "\t")
        }
      case tokeniser.Identifier:
        strings.write_string(&sb, v)
    }
  }
  return strings.to_string(sb), x 
}

token_to_string :: proc(token: $T, token_map:map[string]T) -> string {
  for k,v in token_map {
    if v == token { return k }
  }
  sb := strings.builder_make()
  return fmt.tprint("{0}", token)
}
