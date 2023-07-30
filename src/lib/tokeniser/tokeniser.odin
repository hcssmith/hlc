package tokeniser

import "core:text/scanner"
import "core:unicode/utf8"

import "hlc:buffers"
import "hlc:util/runes"

token_key :: struct($T: typeid) {
  initial:rune,
  length:int,
  full: []rune,
  token:T,
}


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

tokeniser :: proc(token_map: map[string]$T, input_string: string) -> [dynamic]Token(T) {
  token_list := make([dynamic]Token(T))
  rb := buffers.make_runebuffer()

  sc:scanner.Scanner
  scanner.init(&sc, input_string)


  token_key_list:=make([dynamic]token_key(T))

  for k, v in token_map {
    tk:token_key(T)
    tk.full = utf8.string_to_runes(k)
    tk.initial = tk.full[0]
    tk.length = len(k)
    tk.token = v
    append(&token_key_list, tk)
  }

  


  wmp:= make(map[rune]WhitespaceToken)
  wmp[' ']  = WhitespaceToken.Space
  wmp['\t'] = WhitespaceToken.Tab
  wmp['\n'] = WhitespaceToken.NewLine

  for {
    ch := scanner.next(&sc)

    if ch == scanner.EOF {
      s := rb->ToString()
      if s == "" { break }
      if s in token_map {
        append(&token_list, token_map[s])
      } else {
        append(&token_list, s)
      }
      rb->Clear()
      break
    }
    if runes.isWhitespace(ch) {
      s := rb->ToString()
      if s in token_map {
        append(&token_list, token_map[s])
      } else {
        if s != "" {append(&token_list, s)}
      }
      rb->Clear()
      append(&token_list, wmp[ch])
      continue
    }
    tlen:int=0
    ttok:T
    tl: for tk in token_key_list {
      if ch == tk.initial && tk.length > tlen {
        if tlen == 0 {
          s := rb->ToString()
          if s in token_map {
            append(&token_list, token_map[s])
          } else {
            if s != "" {append(&token_list, s)}
          }
          rb->Clear()
        }
        if tk.length == 1 {
          tlen = 1
          ttok = tk.token
          continue
        }
        pass:=true
        for x:=0; x<tk.length; x+=1 {
          if x+1 >= tk.length {break}
          nch:=scanner.peek(&sc, x)
          if nch != tk.full[x+1] {pass = false; break}
        }
        if pass {
          tlen = tk.length
          ttok = tk.token
        }
      }
      continue
    }

    if tlen != 0 {
      append(&token_list, ttok)
      for x:=1; x < tlen; x+=1 {
        scanner.next(&sc)
      }
      continue
    }

    rb->Add(ch)
  }
  
  return token_list
}
