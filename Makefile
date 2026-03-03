.PHONY: dev lint test

dev:
	luarocks install luacheck
	luarocks install busted
	luarocks install lua-cjson
	luarocks install serpent

lint:
	luacheck .

test:
	busted
