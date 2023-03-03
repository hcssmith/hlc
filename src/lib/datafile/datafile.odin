package datafile

import "core:os"
import "core:fmt"
import "core:text/scanner" 

import "hlc:tokeniser"
import "hlc:complextypes"


// NodeTypes
EntityName :: string
NodeName :: string
FileName :: string

Entity :: union {
  string,
  int,
  f64,
}

KnownToken :: enum {
  OpenObject,
  Comment,
  Assignment,
  CloseObject,
}

// Datafile
DataFile :: struct {
  //Data
  p_EntityMap: map[EntityName]Entity,
  p_NodeSet:  map[NodeName]^DataFile,

  //Entity Functions
  SetEntity:proc(^DataFile, EntityName, Entity),
  GetEntity:proc(^DataFile, EntityName) -> Entity,
  GetString:proc(^DataFile, EntityName) -> string,
  GetInt:proc(^DataFile, EntityName) -> int,
  GetF64:proc(^DataFile, EntityName) -> f64,

  //Group Functions
  Node: proc(^DataFile, NodeName) -> ^DataFile,
  AddNode: proc(^DataFile, NodeName, ^DataFile),

  //FileFunctions
  Write: proc(^DataFile, FileName) -> bool,
  Read: proc(^DataFile, FileName) -> bool,
}

ROOTOBJECTID :: "_ROOT_OBJECT_DO_NOT_USE_AS_AN_IDENTTIFIER"


new_datafile :: proc(df: ^DataFile) {
  //Initialize Functions
  df.GetString = getString
  df.GetInt = getInt
  df.GetF64 = getF64
  df.SetEntity = setEntity
  df.GetEntity = getEntity
  df.Node = node
  df.AddNode = addnode
  df.Read = read
}

@(private)
read :: proc(df: ^DataFile, dn: FileName) -> bool {
  fd, _ := os.open(dn)
  size, _ := os.file_size(fd)
  data := make([]u8, size)
  os.read(fd, data[:])
  df.p_EntityMap = make(map[EntityName]Entity)
  df.p_NodeSet = make(map[NodeName]^DataFile)

  token_map: map[string]KnownToken

  token_map["<-"]= KnownToken.Assignment
  token_map["//"]= KnownToken.Comment
  token_map["{"]= KnownToken.OpenObject
  token_map["}"]=KnownToken.CloseObject

  tokens := tokeniser.tokeniser(KnownToken, token_map, string(data))
  
  ptrstk := complextypes.make_ptr_stack(DataFile)

  for x:=0;x<len(tokens);x+=1 
  {
    switch v in tokens[x] {
      case KnownToken:
    }
  }
  return true
}

@(private)
write :: proc(df: ^DataFile, dn: FileName) -> bool { 
  return false
}

@(private)
node :: proc(df: ^DataFile, nn: NodeName) -> ^DataFile {
  if nn in df.p_NodeSet {
    return df.p_NodeSet[nn]
  } 
  createnode(df, nn)
  
  return df.p_NodeSet[nn]
}

@(private)
addnode :: proc(df: ^DataFile, nn: NodeName, n:^DataFile) {
  df.p_NodeSet[nn]=n
}

@(private)
createnode :: proc(df: ^DataFile, nn: NodeName) {
  node:= new(DataFile)
  new_datafile(node)
  df.p_NodeSet[nn] = node
}

@(private)
getString :: proc(df: ^DataFile, en: EntityName) -> string {
  DEF :string=""
  entity := df.p_EntityMap[en]
  switch v in entity {
    case string:
      return entity.(string)
    case int:
      return DEF
    case f64:
      return DEF
  }
  return DEF
}

@(private)
getInt :: proc(df: ^DataFile, en: EntityName) -> int {
  DEF :int=0 
  entity := df.p_EntityMap[en]
  switch v in entity {
    case string:
      return DEF
    case int:
      return entity.(int) 
    case f64:
      return DEF
  }
  return DEF
}

@(private)
getF64 :: proc(df: ^DataFile, en: EntityName) -> f64 {
  DEF :f64=0.0
  entity := df.p_EntityMap[en]
  switch v in entity {
    case string:
      return DEF
    case int:
      return DEF 
    case f64:
      return entity.(f64)
  }
  return DEF
}

@(private)
setEntity :: proc(df: ^DataFile, en: EntityName, e: Entity) {
  df.p_EntityMap[en] = e
}

@(private)
getEntity :: proc(df: ^DataFile, en: EntityName) -> Entity {
  return df.p_EntityMap[en]
}
