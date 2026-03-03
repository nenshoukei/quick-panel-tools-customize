.PHONY: dev lint test

dev:
	luarocks install luacheck
	luarocks install busted
	luarocks install lua-cjson

lint:
	luacheck .

test:
	busted
