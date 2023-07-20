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

  d := df.load("test.dat")

  for node in d.NodeCollection {
    fmt.printf("Node:{0}\nChildern{1}\nName:{2}\nValue:{3}\n\n\n", node.ID, node.Children, node.Name, node.Value)
  }

}
