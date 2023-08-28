package xml

import "hlc:tokeniser"
import "core:strings"
import "core:fmt"

Token :: tokeniser.Token
TC_INDEX_BEGIN :: -1

StepFunc  :: proc(^TokenCollection(KnownToken)) -> (Token(KnownToken), bool)
TTSFunc   :: proc(^TokenCollection(KnownToken), Token(KnownToken)) -> string 
AdvFunc   :: proc(^TokenCollection(KnownToken), Token(KnownToken)) 
PeekFunc  :: proc(^TokenCollection(KnownToken), int) -> Maybe(Token(KnownToken))

TokenCollection :: struct($T: typeid) {
  Ptr:int,
  Length:int,
  Tokens:[]Token(T),
  TokenMap:map[string]KnownToken,

  Next:           StepFunc,
  Prev:           StepFunc,
  Peek:           PeekFunc,
  AdvanceTo:      AdvFunc,
  TokenToString:  TTSFunc,
}


make_token_collection :: proc(tl: [dynamic]Token(KnownToken), tm: map[string]KnownToken) -> ^TokenCollection(KnownToken)
{
  tc := new(TokenCollection(KnownToken))
  tc.Ptr = TC_INDEX_BEGIN
  tc.Length = len(tl)
  tc.Tokens = make([]Token(KnownToken), tc.Length)
  tc.TokenMap = tm
  copy_slice(tc.Tokens, tl[:])

  tc.Next = next_func
  tc.Prev = prev_func
  tc.TokenToString = token_to_string2
  tc.Peek = peek_func
  tc.AdvanceTo = advance_to_token

  return tc
}

advance_to_token :: proc(tc:^TokenCollection(KnownToken), tok: Token(KnownToken)) {
  for token in tc->Next() {
    if cmp(token, tok) { break }
  }
}

next_func :: proc(tc: ^TokenCollection(KnownToken)) -> (Token(KnownToken), bool) {
  tc.Ptr += 1
  if tc.Ptr >= tc.Length { return nil, false }
  return tc.Tokens[tc.Ptr], true
}

prev_func :: proc(tc: ^TokenCollection(KnownToken)) -> (Token(KnownToken), bool) {
  tc.Ptr -= 1
  if tc.Ptr < 0 { return nil, false }
  return tc.Tokens[tc.Ptr], true
}

cmp :: proc(t1: Token(KnownToken), t2:Token(KnownToken)) -> bool {
  switch v in t1 {
    case KnownToken:
      if tok, ok := t2.(KnownToken); ok && t1 == tok { return true }
    case tokeniser.Identifier:
      if tok, ok := t2.(tokeniser.Identifier); ok && t1 == tok { return true }
    case tokeniser.WhitespaceToken:
      if tok, ok := t2.(tokeniser.WhitespaceToken); ok && t1 == tok { return true }
  }
  return false
}

is_ident :: proc(t: Token(KnownToken)) -> bool {
  _, ok := t.(tokeniser.Identifier)
  return ok
}

peek_func :: proc(tc: ^TokenCollection(KnownToken), ind:int) -> Maybe(Token(KnownToken)) {
  if ind > tc.Length || ind < 0 { return nil }
  return tc.Tokens[ind]
}


token_to_string2 :: proc(tc:^TokenCollection(KnownToken), token:Token(KnownToken)) -> string {
  switch v in token {
    case KnownToken:
      for k,val in tc.TokenMap {
        if val == v { return k }
      }
      return "" 
    case tokeniser.Identifier:
      return v
    case tokeniser.WhitespaceToken:
      switch v {
        case .Space:
          return " "
        case .NewLine:
          return "\n"
        case .Tab:
          return "\t"
      }
  }
  return ""
}
