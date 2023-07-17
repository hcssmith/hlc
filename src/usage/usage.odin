package usage

import df "hlc:datafile"
import ct "hlc:complextypes"
import bf "hlc:buffers"
import tk "hlc:tokeniser"

import "core:fmt"

example_enum :: enum {
  OneEntry,
}

main :: proc() {

  datafile:=df.new_datafile()

  datafile->Read("./test.dat")

  runebuf := bf.make_runebuffer() 
  runebuf->Add('5')

  fmt.printf("{0}\n", runebuf)
  fmt.printf("{0}\n", runebuf->ToString())

  test: tk.Token(int)
  test = "one"
  fmt.printf("{0}\n", test)
  test = 6 
  fmt.printf("{0}\n", test)

  mp := make(map[string]example_enum)
  mp["1"] = .OneEntry
  p := tk.tokeniser(example_enum, mp, "1 identifier")

  fmt.printf("{0}\n", p)


  stack := ct.make_stack(string)

  ct.Push(string, stack, "First")
  ct.Push(string, stack, "Second")
  ct.Push(string, stack, "Third")

  a:= ct.Skim(string, stack).?
  fmt.printf("{0}\n", a)
  a= ct.Pop(string, stack).?
  fmt.printf("{0}\n", a)
  a= ct.Pop(string, stack).?
  fmt.printf("{0}\n", a)
  a= ct.Pop(string, stack).? or_else ""
  fmt.printf("{0}\n", a)


  
}
