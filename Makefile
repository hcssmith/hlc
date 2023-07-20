all: run_dbg

release:
	odin build ./src/usage -collection:hlc=src/lib -out:hlc_usage

debug:
	odin build ./src/usage -debug -collection:hlc=src/lib -out:hlc_usage_dbg

run: release
	./hlc_usage

run_dbg: debug
	./hlc_usage_dbg

clean:
	rm -f hlc_usage
	rm -f hlc_usage_dbg
