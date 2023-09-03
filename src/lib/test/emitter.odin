package test

import "core:strings"
import "core:fmt"
import "core:os"

Pkgid :: int

File :: struct {
  Imports: [dynamic]Import,
  TestFunctions:[dynamic]Function,
}

Function :: struct {
  Name:string,
  Pkg:Pkgid,
  Args:[dynamic]Arg,
  Line:int,
  File:string,
}

Arg :: struct {
  Name:string,
  Value:string,
}

Import :: struct {
  Id: Pkgid,
  Collection:string,
  Library:string,
  Alias: string,
}

print_file :: proc(f: File, out:string) {
  sb := strings.builder_make()

  strings.write_string(&sb, "package test_runner_tmp\n")

  for im in f.Imports {
    print_import(&sb, im)
  }

  strings.write_string(&sb, "main :: proc() {\n")
  strings.write_string(&sb, "t:=test.new_t()\n")

  for function in f.TestFunctions {
    pkgname:string
    for pkg in f.Imports {
      if pkg.Id == function.Pkg { 
        pkgname = pkg.Alias if pkg.Alias != "" else pkg.Library 
      }
    }
    fn: Function
    fn.Name = "register_test"
    fn.Pkg = TESTLIBID 
    targ := Arg{"", "t"}
    narg := Arg{"", fmt.tprintf("\"{0}\"", function.Name)}
    larg := Arg{"", fmt.tprintf("{0}", function.Line)}
    farg := Arg{"", fmt.tprintf("\"{0}\"", function.File)}
    arg := Arg{"", fmt.tprintf("{0}.{1}", pkgname, function.Name)}
    append(&fn.Args, targ)
    append(&fn.Args, arg)
    append(&fn.Args, narg)
    append(&fn.Args, larg)
    append(&fn.Args, farg)
    call_function(&sb, f, fn)
  }


  strings.write_string(&sb, "test.runner(t)\n")
  strings.write_string(&sb, "}\n")


  FileMethod  :=  os.O_CREATE | os.O_WRONLY | os.O_TRUNC
  Permissions :=  os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IWGRP

  fd, _ := os.open(out, FileMethod, Permissions)
  defer os.close(fd)
  os.write_string(fd, strings.to_string(sb))
}

call_function :: proc(sb: ^strings.Builder, file:File, fn: Function) {
  pkg: string
  for i in file.Imports {
    if fn.Pkg == i.Id {
      pkg = i.Alias if i.Alias != "" else i.Library
      break
    }
  }
  fmt.sbprintf(sb, "{0}.{1}(", pkg, fn.Name)
  for x:=0;x<len(fn.Args);x+=1 {
    if x == len(fn.Args) - 1 {
      fmt.sbprintf(sb, "{0}", arg_to_string(fn.Args[x]))
    } else {
      fmt.sbprintf(sb, "{0},", arg_to_string(fn.Args[x]))
    }
  }
  strings.write_string(sb, ")\n")
}

arg_to_string :: proc(a: Arg) -> string {
  sb := strings.builder_make()
  if a.Name != "" {
    return fmt.tprintf("{0}={1}", a.Name, a.Value)
  } else {
    return fmt.tprintf("{0}", a.Value)
  }
}

print_import :: proc(sb: ^strings.Builder, im: Import) {
  fmt.sbprintf(sb, "import {0} \"{1}:{2}\"\n", im.Alias, im.Collection, im.Library)
}
