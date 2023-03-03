package runes

isWhitespace :: proc(ch: rune) -> bool {
  if ch == ' ' || ch == '\t' || ch == '\n' {
    return true
  }
  return false
}
