include config.mk


.PHONY: test clean test-runner

default: run_dbg

test:
	odin test $(test_dir) $(hlc) 

release:
	odin build $(example) $(hlc) -out:hlc_usage

test-runner:
	odin run $(test-runner) $(hlc) $(tests) 

debug:
	odin build $(example) -debug $(hlc) -out:hlc_usage_dbg

run: release
	./hlc_usage

run_dbg: debug
	./hlc_usage_dbg

clean:
	rm -f test
	rm -f test-runner
	rm -f hlc_usage
	rm -f hlc_usage_dbg
