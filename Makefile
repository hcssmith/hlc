all: run

release:
	odin build ./src/usage -collection:hlc=src/lib -out:hlc_usage

run: release
	./hlc_usage
