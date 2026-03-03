.PHONY: dev lint

dev:
	luarocks install luacheck

lint:
	luacheck .
