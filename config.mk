hlc = -collection:hlc=./src/lib
tests = -collection:tests=./src/tests
example = ./src/usage
test_dir = ./src/test
test-runner = ./src/test-runner

test-runner-src = ./src/test-runner/main.odin 
hlc-src = $(wildcard src/lib/**/*.odin) 
hlc-test-src = $(wildcard src/lib/test/*.odin) 
tests-src = $(wildcard src/test/**/*.odin) 

