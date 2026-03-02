.PHONY: dev lint release

dev:
	luarocks install luacheck

lint:
	luacheck .

release:
	./make-release-zip.sh
