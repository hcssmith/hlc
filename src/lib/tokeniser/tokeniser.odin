package parser

import "core:text/scanner"

import "hlc:buffers"
import "hlc:util/runes"

Token :: union($T: typeid) {
  Identifier,
  WhitespaceToken,
  T,
}

Identifier :: string

WhitespaceToken :: enum {
  Space,
  Tab,
  NewLine,
}

tokeniser :: proc($T: typeid, token_map: map[string]T, input_string: string) -> [dynamic]Token(T) {
  toklist:[dynamic]Token(T)
  rb:= buffers.make_runebuffer()
  sc: scanner.Scanner
  scanner.init(&sc, input_string)

  wmp: map[rune]WhitespaceToken
  wmp[' ']=WhitespaceToken.Space
  wmp['\t']=WhitespaceToken.Tab
  wmp['\n']=WhitespaceToken.NewLine
  
  for {
    ch := scanner.next(&sc)
    if ch == scanner.EOF {
      s := rb->ToString()
      if s == "" { break }
      if s in token_map {
        append(&toklist, token_map[s])
      } else {
        append(&toklist, s)
      }
      rb->Clear()
      break
    }
    if runes.isWhitespace(ch) {
      s := rb->ToString()
      if s == "" { continue }
      if s in token_map {
        append(&toklist, token_map[s])
      } else {
        append(&toklist, s)
      }
      rb->Clear()
      append(&toklist, wmp[ch])
      continue
    }
    rb->Add(ch)
  }
  return toklist
}

