package test

import "core:fmt"
import "core:os"
import "core:runtime"
import "core:reflect"
import "core:odin/ast"
import "core:odin/parser"

TestFunc :: #type proc(^T)

T :: struct {
  TCount: int,
  TSuccess: int,
  Tests: [dynamic]Test,
  TStatus: bool,
  TMessage: string,
}

Test :: struct {
  fn: TestFunc,
  name: string,
  loc: TestLocation,
}

TestLocation :: struct {
  line:int,
  file:string,
}

RunnerOptions :: struct {
  JsonOnly:bool,
}

DEFAULT_OPTIONS :RunnerOptions: { true, }

print_test_info :: proc(test: Test, success:bool) {
  fmt.printf("{{\"function\":\"{0}\",\"location\":\"{1}\",\"success\":\"{2}\"}}\n",test.name, test.loc.line, success)
}

register_test :: proc(t: ^T, fn: TestFunc, name:string, pkg_location:string) {
  tst := new(Test)
  tst.fn = fn
  tst.name = name 
  tst.loc = extract_test_location(pkg_location, name)
  append(&t.Tests, tst^)
}

expect :: proc(t: ^T, condition: bool, msg:string="") {
  if condition { 
    t.TStatus = true 
  } else {
    t.TStatus = false
    t.TMessage = msg
  }
}

new_t :: proc() -> ^T {
  t := new(T) 
  t.Tests = make([dynamic]Test)
  return t
}

runner :: proc(t:^T, opts:RunnerOptions=DEFAULT_OPTIONS) {
  for test in t.Tests {
    t.TStatus = false
    t.TCount +=1
    test.fn(t)
    if t.TStatus { t.TSuccess += 1 }
    print_test_info(test, t.TStatus)
  }

  if !opts.JsonOnly {
    fmt.printf("{0}/{1} Tests succesful\n", t.TSuccess, t.TCount)
  }
}

has_test_attr :: proc(n: ^ast.Value_Decl) -> bool {
  for attr in n.attributes {
    for e in attr.elems {
      if id, ok := e.derived_expr.(^ast.Ident); ok {
        if id.name == "test" { return true }
      }
    }
  }
  return false
}

extract_test_location :: proc(test_collection: string, proc_name: string) -> TestLocation{
  tl := make([dynamic]Test)


  pkg, ok := parser.parse_package_from_path(test_collection)

  if !ok {
    fmt.printf("ERROR: could not parse package location")
    os.exit(1)
  }

  for file in pkg.files {
    for decl in pkg.files[file].decls {
      if v, ok := decl.derived_stmt.(^ast.Value_Decl); ok {
        pname, is_ident := v.names[0].derived_expr.(^ast.Ident)
        p,  is_proc  := v.values[0].derived_expr.(^ast.Proc_Lit)
        if is_ident && is_proc {
          if pname.name == proc_name {
           return TestLocation{
              decl.pos.line,
              decl.pos.file,
            }
          }
        }
      }
    }
  }
  return {}
}


