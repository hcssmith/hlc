package xml

import "core:strings"
import "core:fmt"
import "core:log"
import "hlc:util/ustring"
import "hlc:tokeniser"

PRUNE_NODE :: -2
XML_VERSION :: "__XML_VERSION__"
XML_ENCODING :: "__XML_ENCODING__"


XMLNodeCollection :: struct {
  LatestNodeID: NodeID,
  LatestPIID: int,
  Nodes: [dynamic]^XMLNode,
  RootNode: NodeID,
  XMLDeclaration: XMLDeclaration,
  ProcessingInstructions: [dynamic]^ProcessingInstruction,
  //interface
  add_node: proc(^XMLNodeCollection, ^XMLNode),
  get_node_by_id: proc(^XMLNodeCollection, NodeID) -> ^XMLNode,
  pretty_print: proc(^XMLNodeCollection),
  parse_string: proc(^XMLNodeCollection, string),
  prune_nodelist: proc(^XMLNodeCollection),
  add_processing_instruction: proc(^XMLNodeCollection, ^ProcessingInstruction),
  prune_processing_instrcutions: proc(^XMLNodeCollection),
  }

XMLDeclaration :: struct {
  Version:string,
  Encoding:string,
}

ProcessingInstruction :: struct {
  Id:int,
  Name:string,
  Keys: map[string]string,
}

make_node_collection :: proc() -> XMLNodeCollection {
  nc:XMLNodeCollection
  nc.LatestNodeID = -1
  nc.LatestPIID = -1
  nc.Nodes = make([dynamic]^XMLNode)
  nc.ProcessingInstructions = make([dynamic]^ProcessingInstruction)
  nc.add_node = add_node
  nc.pretty_print = pretty_print
  nc.get_node_by_id = get_node_by_id
  nc.parse_string = parse_string
  nc.prune_nodelist = prune_nodelist
  nc.prune_processing_instrcutions = prune_processing_instrcutions
  nc.add_processing_instruction = add_processing_instruction
  return nc
  }

add_processing_instruction :: proc(nc:^XMLNodeCollection, pi: ^ProcessingInstruction) {
  pi := pi
  nc.LatestPIID +=1
  pi.Id = nc.LatestPIID 
  append(&nc.ProcessingInstructions, pi) 
}

add_node :: proc(nc: ^XMLNodeCollection, node: ^XMLNode) {
  when ODIN_DEBUG { log.debugf("Adding {0} Node: {1}", node.Type, node.Name) }
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
  if !node.SelfClosing { strings.write_string(&tb, ">") }
  return strings.to_string(tb)
}

node_to_text :: proc(nc: ^XMLNodeCollection, nodeid: int, indent_level: int = 0) -> string {
  indent := ustring.repeat_string("\t", indent_level)
  sb:=strings.builder_make()
  node := nc->get_node_by_id(nodeid)
  if node.Type == .Text {
    strings.write_string(&sb, node.Text)
    return strings.to_string(sb)
  }
  fmt.sbprintf(&sb, "{0}{1}", indent, opening_tag(nc, node))
  if node.SelfClosing && node.Type != .Cdata {
    strings.write_string(&sb, " />\n")
    return strings.to_string(sb)
  }
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
  } else if node.Text != "" && node.Type != .Cdata {
    fmt.sbprintf(&sb, "</")
  } else if node.Type != .Cdata {
    fmt.sbprintf(&sb, "{0}</", indent)
  } else {
    fmt.sbprintf(&sb, "]]>\n")
    return strings.to_string(sb)
  }
  if node.Namespace != "" {
    fmt.sbprintf(&sb, "{0}:", node.Namespace)
  }
  fmt.sbprintf(&sb, "{0}>\n", node.Name)
  return strings.to_string(sb)
}

pretty_print :: proc(self: ^XMLNodeCollection) {

  when ODIN_DEBUG { log.debug(self.XMLDeclaration) }

  if self.XMLDeclaration.Version != "" || self.XMLDeclaration.Encoding != "" {
    fmt.printf("<?xml version=\"{0}\" encoding=\"{1}\"?>\n", self.XMLDeclaration.Version, self.XMLDeclaration.Encoding)
  }
  for pi in self.ProcessingInstructions {
    fmt.printf("<?{0}", pi.Name)
    for k,v in pi.Keys {
      fmt.printf(" {0}=\"{1}\"",k,v)
    }
    fmt.printf("?>\n")
  }
  fmt.printf("{0}\n", node_to_text(self, self.RootNode))

}

KnownToken :: enum {
  OpenTag,
  CloseTag,
  CloseIndicator,
  Escape,
  Quote,
  DoubleQuote,
  Assign,
  CommentOpen,
  CommentClose,
  NamespaceIndicator,
  ProcessingInstructionBegin,
  ProcessingInstructionEnd,
  CDataBegin,
  CDataEnd,
}


parse_string :: proc(nc: ^XMLNodeCollection, xmlstring:string) {
  nc.Nodes = make([dynamic]^XMLNode)
  nc.LatestNodeID = -1
  nc.RootNode = -1

  root_node := new_node(.Elem, ROOTNODE)

  nc->add_node(root_node)
  nc.RootNode = root_node.ID

  token_map:map[string]KnownToken

  token_map["<"]          = .OpenTag
  token_map["<?"]         = .ProcessingInstructionBegin
  token_map["?>"]         = .ProcessingInstructionEnd
  token_map["<!--"]       = .CommentOpen
  token_map["-->"]        = .CommentClose
  token_map[">"]          = .CloseTag
  token_map["/"]          = .CloseIndicator
  token_map["\\"]         = .Escape
  token_map["'"]          = .Quote
  token_map["\""]         = .DoubleQuote
  token_map["="]          = .Assign
  token_map[":"]          = .NamespaceIndicator
  token_map["<![CDATA["]  = .CDataBegin
  token_map["]]>"]        = .CDataEnd


  tokens := tokeniser.tokeniser(token_map, xmlstring)

  tc := make_token_collection(tokens, token_map)

  cn := root_node
  parent := root_node.ParentID

  sb := strings.builder_make()
  
  for token in tc->Next() {
    log.debugf("PARSE LEVEL{0}", token)
    switch v in token {
      case KnownToken:
        switch v {
          case .CDataBegin:
            cd := strings.builder_make()
            n := new_node(.Cdata, "")
            for token in tc->Next() {
              if cmp(token, .CDataEnd) {
                n->set_text(strings.to_string(cd))
                break
              } else {
                strings.write_string(&cd, tc->TokenToString(token))
              }
            }
            nc->add_node(n)
            cn->add_child(n)
          case .ProcessingInstructionBegin:
            n, attrs :=process_open_tag(tc)
            pi := new(ProcessingInstruction)
            pi.Name = n.Name
            for attr in attrs {
              if pi.Name == "xml" && strings.to_upper(attr.Name) == "VERSION" {
                pi.Keys[XML_VERSION] = attr.Text
              } else if pi.Name == "xml" && strings.to_upper(attr.Name) == "ENCODING" {
                pi.Keys[XML_ENCODING] = attr.Text
              } else {
                pi.Keys[attr.Name] = attr.Text
              }
            }
            nc->add_processing_instruction(pi)

          case .CommentOpen:
            cs := process_comment(tc)
            n := new_node(.Elem, COMMENT)
            n->set_text(cs)
            nc->add_node(n)
            cn->add_child(n)
          case .OpenTag:
            if strings.builder_len(sb) > 0 {
              te := new_node(.Text, strings.to_string(sb))
              nc->add_node(te)
              cn->add_child(te)
              sb = strings.builder_make()
            }
            if cmp(tc->Peek(tc.Ptr+1).?, .CloseIndicator) {
              tc.Ptr += 1
              n, _ := process_open_tag(tc)
              if n.Name == cn.Name && n.Namespace == cn.Namespace {
                if len(cn.Children) == 1 {
                  tn := nc->get_node_by_id(cn.Children[0])
                  if tn.Type == .Text {
                    cn->set_text(tn.Text)
                    tn.ParentID = PRUNE_NODE
                    cn.Children = make([dynamic]NodeID)
                  }
                }
                cn = nc->get_node_by_id(parent)
                parent = cn.ParentID
                continue
              }
            }
            n, attrs := process_open_tag(tc)
            nc->add_node(n)
            cn->add_child(n)
            for attr in attrs {
              fmt.printf("{0}", attr->to_string())
              nc->add_node(attr)
              n->add_attr(attr)
            }
            if !n.SelfClosing {
              cn = n
              parent = n.ParentID
            }
          case .CloseTag, .CloseIndicator, .CommentClose, .Quote, .ProcessingInstructionEnd, .DoubleQuote, .Assign, .NamespaceIndicator, .Escape, .CDataEnd:
        }
      case tokeniser.Identifier, tokeniser.WhitespaceToken:
        strings.write_string(&sb, tc->TokenToString(token))
    }
  }
  
  if len(root_node.Children) == 1
  {
    n := nc->get_node_by_id(root_node.Children[0])
    n.ParentID = 0
    nc.RootNode = n.ID
    root_node.Children = make([dynamic]NodeID)
    root_node.ParentID = PRUNE_NODE
  }

  for pi in nc.ProcessingInstructions {
    if pi.Name == "xml" {
      nc.XMLDeclaration.Version = pi.Keys[XML_VERSION]
      nc.XMLDeclaration.Encoding = pi.Keys[XML_ENCODING]
      pi.Id = PRUNE_NODE
    }
  }

  nc->prune_nodelist()
  nc->prune_processing_instrcutions()

  nc->pretty_print()
}

process_open_tag :: proc(tc: ^TokenCollection(KnownToken)) -> (^XMLNode, [dynamic]^XMLNode) {
  attrs := make([dynamic]^XMLNode)
  n:=new_node(.Elem, "", "")

  s:=tc->Peek(tc.Ptr + 1)
  s2:=tc->Peek(tc.Ptr + 2).?

  if cmp(s2, .NamespaceIndicator) {
    s3 := tc->Peek(tc.Ptr + 3)
    n.Name = tc->TokenToString(s3.?)
    n.Namespace = tc->TokenToString(s.?)
    tc.Ptr += 3
  } else {
    n.Name = tc->TokenToString(s.?)
    tc.Ptr += 1
  }

  for token in tc->Next() {
    log.debugf("PROCESSING TOPLEVEL: {0}", token)
    if cmp(token, .CloseTag) || cmp(token, .ProcessingInstructionEnd) {
      log.debug("CLOSING")
      break
    }
    if tok, ok := token.(tokeniser.Identifier); ok {
      attr := new_node(.Attr, "")
      if cmp(tc->Peek(tc.Ptr +1).?, .NamespaceIndicator) {
        if tok_en, ok := tc->Peek(tc.Ptr +2).?.(tokeniser.Identifier); ok {
          attr.Namespace = tok
          attr.Name = tok_en
          tc.Ptr +=2
        }
      } else {
        attr.Name = tok
      }
      attr_loop: for token in tc->Next() {
        log.debugf("PROCESSING ATTR LEVE: {0}", token)
        if cmp(token, .Assign) {
          start_location := tc.Ptr
          tc->AdvanceTo(.Quote)
          ql := tc.Ptr
          tc.Ptr = start_location
          tc->AdvanceTo(.DoubleQuote)
          dql := tc.Ptr
          tc.Ptr = ql > dql ? dql : ql 
          nt := ql > dql ? KnownToken.DoubleQuote : KnownToken.Quote
          sb := strings.builder_make()
          for token in tc->Next() {
            log.debugf("PROCESSING VAL LEVE: {0}", token)
            if cmp(token, nt) && !cmp(tc->Peek(tc.Ptr-1).?, .Escape){
              attr.Text = strings.to_string(sb)
              break attr_loop
            }
            strings.write_string(&sb, tc->TokenToString(token))
          }
        } else if is_ident(token) {
          tc.Ptr -=1
          break
        } else if cmp(token, .CloseIndicator) {
          n.SelfClosing = true
        }

      }
      if attr.Namespace == "xmlns" {
        n.NamespacesInScope[attr.Name] = attr.Text
      } else if attr.Name == "xmlns" {
        n.NamespacesInScope[DEFAULTNAMESPACE] = attr.Text
      } else {
        append(&attrs, attr)
      }
    }
    if cmp(token, .CloseIndicator) {
      n.SelfClosing = true
    }
  }
  return n, attrs
  
}

process_comment :: proc(tc: ^TokenCollection(KnownToken)) -> string {
  nesting_level:int
  sb := strings.builder_make()
  for token in tc->Next() {
    if tok, ok := token.(KnownToken); ok && tok == .CommentClose { 
      if nesting_level == 0 { break }
      nesting_level-=1
    }
    if tok, ok := token.(KnownToken); ok && tok == .CommentOpen { 
      nesting_level+=1
    }
    strings.write_string(&sb, tc->TokenToString(token))
  }
  return strings.to_string(sb)
}


prune_nodelist :: proc(nc: ^XMLNodeCollection) {
  nl := make([dynamic]^XMLNode)
  for node in nc.Nodes {
    if node.ParentID == PRUNE_NODE {
      log.warnf("Removing: {0}", node.Name)
    } else {
      append(&nl, node)
    }
  }
  nc.Nodes = nl
}

prune_processing_instrcutions :: proc(nc: ^XMLNodeCollection) {
  nl := make([dynamic]^ProcessingInstruction)
  for pi in nc.ProcessingInstructions {
    if pi.Id == PRUNE_NODE {
      log.warnf("Removing PI: {0}", pi.Name)
    } else {
      append(&nl, pi)
    }
  }
  nc.ProcessingInstructions = nl
}


token_to_string :: proc(token: $T, token_map:map[string]T) -> string {
  for k,v in token_map {
    if v == token { return k }
  }
  sb := strings.builder_make()
  return fmt.tprint("{0}", token)
}
