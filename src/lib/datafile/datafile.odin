package datafile

import "core:os"
import "core:fmt"
import "core:strings"
import "hlc:tokeniser"
import "hlc:util/ustring"

KnownToken :: enum {
  OpenObject,
  Comment,
  Assignment,
  CloseObject,
}


ROOTOBJECTID :: "_ROOT_OBJECT_DO_NOT_USE_AS_AN_IDENTTIFIER"

DataFile :: struct {
  RootNode: int,
  LatestID: int,
  NodeCollection: [dynamic]^Node,
  AddNode: proc(^DataFile, ^Node),
  GetNodeByID: proc(^DataFile, int) -> ^Node,
  GetString: proc(^DataFile, string) -> string,
  SetString: proc(^DataFile, string, string),
  Save: proc(^DataFile, string),
  }

// df->SetString("this.is.a.path", "This is a value")
SetString :: proc(df: ^DataFile, key: string, value:string) {
  path := strings.split(key, ".")
  rn := df->GetNodeByID(df.RootNode)
  cn := rn
  path_loop: for step in path {
    for id in cn.Children {
      wn := df->GetNodeByID(id)
      if wn.Name == step {
        cn = wn
        continue path_loop 
      }
    }
    nn := new_node()
    nn.Name = step
    df->AddNode(nn)
    cn->AddChild(nn)
    cn = nn
  }
  cn.Value = value
}

GetString :: proc(df: ^DataFile, key: string) -> string {
  path := strings.split(key, ".")
  rn := df->GetNodeByID(df.RootNode)
  cn := rn
  path_loop: for step in path {
    for id in cn.Children {
      wn := df->GetNodeByID(id)
      if wn.Name == step {
        cn = wn
        continue path_loop 
      }
    }
    return ""
  }
  return cn.Value
}


GetNodeByID :: proc(s: ^DataFile, i: int) -> ^Node {
  for node in s.NodeCollection {
    if node.ID == i {
      return node
    }
  }
  return nil
}

AddNode :: proc(df: ^DataFile, n: ^Node) {
  if df.LatestID == -1 {
    df.LatestID = 0
  } else {
    df.LatestID +=1
  }
  n.ID = df.LatestID
  append(&df.NodeCollection, n)
}

Node :: struct {
  ID: int,
  Parent: int,
  Name: string,
  Value: string,
  Children: [dynamic]int,
  AddChild: proc(^Node, ^Node),
}

AddChild:: proc(s: ^Node, c: ^Node) {
  c.Parent = s.ID
  append(&s.Children, c.ID)
}

new_node :: proc() -> ^Node {
  n := new(Node)
  n.Children = make([dynamic]int)
  n.AddChild = AddChild
  return n
}
  

make_datafile :: proc() -> DataFile {
  df := new(DataFile)
  df.RootNode = -1;
  df.LatestID = -1;
  df.NodeCollection = make([dynamic]^Node)
  df.AddNode = AddNode
  df.GetNodeByID = GetNodeByID
  df.SetString = SetString
  df.GetString = GetString
  df.Save = Save
  return df^
  }

FileMethod  ::  os.O_CREATE | os.O_WRONLY | os.O_TRUNC
Permissions ::  os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IWGRP

Save :: proc(df: ^DataFile, filename: string) {
  fd, _ := os.open(filename, FileMethod, Permissions)
  defer os.close(fd)
  os.write_string(fd, node_to_string(df, df.RootNode))
  }

node_to_string :: proc(df: ^DataFile, current_node_id: int, indent_count:int=0) -> string {
  indent := ustring.repeat_string("\t", indent_count)
  
  sb := strings.builder_make()
  cn := df->GetNodeByID(current_node_id)

  if cn.Name == ROOTOBJECTID {
    strings.write_string(&sb, "{\n")
    for child in cn.Children {
      strings.write_string(&sb, node_to_string(df, child, indent_count +1) )
    }
    strings.write_string(&sb, "}\n")
    return strings.to_string(sb)
  }

  if cn.Value != "" {
    fmt.sbprintf(&sb, "{0}{1} <- {2}\n",indent, cn.Name, cn.Value)
  } else {
    fmt.sbprintf(&sb, "{0}{1}\n{2}{{\n", indent, cn.Name, indent)
    for child in cn.Children {
      strings.write_string(&sb, node_to_string(df, child, indent_count +1))
    }
    fmt.sbprintf(&sb, "{0}}}\n", indent)
  }
  return strings.to_string(sb)
}

load :: proc(file: string = "") -> DataFile {
  df := make_datafile()
  
  root_node := new_node()
  df->AddNode(root_node)

  root_node.Name = ROOTOBJECTID
  root_node.Value = ROOTOBJECTID

  df.RootNode = root_node.ID


  if file == "" { return df }
  fd, _ := os.open(file)
  defer os.close(fd)
  size, _ := os.file_size(fd)
  data := make([]u8, size)
  os.read(fd, data[:])

  token_map:map[string]KnownToken

  token_map["<-"] = KnownToken.Assignment
  token_map["//"] = KnownToken.Comment
  token_map["{"] = KnownToken.OpenObject
  token_map["}-"] = KnownToken.CloseObject


  tokens := tokeniser.tokeniser(KnownToken, token_map, string(data))
  
  cn : ^Node= root_node

  skipped:=false

  last_ident:tokeniser.Identifier

  for x:=0; x<len(tokens); x+=1 {
    token := tokens[x]
    switch v in token {
      case tokeniser.Identifier:
        last_ident = token.(tokeniser.Identifier)
      case tokeniser.WhitespaceToken:
        continue 
      case KnownToken:
        switch token.(KnownToken) {
          case .OpenObject:
            if cn.Name == ROOTOBJECTID && !skipped { skipped=true; continue } //Skip first object
            n := new_node()
            n.Name = last_ident
            df->AddNode(n)
            cn->AddChild(n)
            cn = n
          case .CloseObject:
            cn = df->GetNodeByID(cn.Parent)
            if cn == nil {
              return df
            }
          case .Comment:
            comm_loop: for {
              x += 1
              #partial switch v in tokens[x]{
                  case tokeniser.WhitespaceToken:
                    if tokens[x].(tokeniser.WhitespaceToken) == .NewLine {
                      break comm_loop
                    }
                  case:
                    continue
              }
            }
          case .Assignment:
            n := new_node()
            n.Name = last_ident
            sb := strings.builder_make()
            assign_loop: for {
              x+=1
              switch v in tokens[x] {
                case tokeniser.Identifier:
                  strings.write_string(&sb, tokens[x].(tokeniser.Identifier))
                case tokeniser.WhitespaceToken:
                  switch tokens[x].(tokeniser.WhitespaceToken) {
                    case .NewLine:
                      break assign_loop
                    case .Tab:
                      strings.write_string(&sb, "\t")
                    case .Space:
                       strings.write_string(&sb, " ")
                  }
                case KnownToken:
                  switch tokens[x].(KnownToken) {
                    case .Assignment:
                      strings.write_string(&sb, "<-")
                    case .Comment:
                      break assign_loop
                    case .CloseObject: // { for editor brace balancing
                       strings.write_string(&sb, "}")
                    case .OpenObject:
                       strings.write_string(&sb, "{") //} for editor brace balancing
                  }
            }
            }
            n.Value = strings.to_string(sb)
            df->AddNode(n)
            cn->AddChild(n)
    }
  }
    
  }
  return df
}
