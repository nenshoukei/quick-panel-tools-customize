.PHONY: dev lint

dev:
	luarocks install luacheck
	wget -O .luacheckrc https://raw.githubusercontent.com/Nexela/Factorio-luacheckrc/0.17/.luacheckrc

lint:
	luacheck .
