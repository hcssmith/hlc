include config.mk


.PHONY: clean 

default: run_dbg

test: test-runner $(tests-src) $(hlc-src)
	@odin run ./tmp_test.odin -file $(hlc) $(tests)

release: $(hlc-src)
	odin build $(example) $(hlc) -out:hlc_usage

test-runner: $(hlc-test-src) $(test-runner-src)
	@odin run $(test-runner) $(hlc) $(tests)

debug: $(hlc-src)
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
	rm -f tmp_test
	rm -f tmp_test.odin
