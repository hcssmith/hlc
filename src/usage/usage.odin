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

  d := df.load("test2.dat")

  d->SetString("node.step1.string1", "This is some other text")
  d->SetString("node.step1.string3", "This is other set of text point 2")


  d->Save("test2.dat")


}
