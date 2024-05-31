
LIBLUA=/usr/lib/x86_64-linux-gnu/liblua5.2.a
LIBLUA_WIN=/usr/x86_64-w64-mingw32/lib/liblua5.2.a
LUAINCLUDE=/usr/include/lua5.2

WINCC=x86_64-w64-mingw32-gcc

default: build/paisley

build:
	mkdir build

build/paisley: build/luastatic.lua build/paisley_standalone.lua
	./$^ $(LIBLUA) -I$(LUAINCLUDE) -static
	mv paisley_standalone $@

build/paisley.exe: build/luastatic.lua build/paisley_standalone.lua build/lua/lua.exe
	CC=$(WINCC) $< build/paisley_standalone.lua $(LIBLUA) -I$(LUAINCLUDE)

build/paisley_standalone.lua: build
	python3 build.py

build/luastatic.lua: build
	wget https://raw.githubusercontent.com/ers35/luastatic/master/luastatic.lua --output-document=$@ --no-use-server-timestamps
	chmod +x $@

build/lua: build
	wget http://www.lua.org/ftp/lua-5.4.6.tar.gz --no-use-server-timestamps --output-document=build/lua.tar.gz
	tar -xzf build/lua.tar.gz -C build/
	rm build/lua -rf
	mv build/lua-5.4.6 $@

build/lua/src/lua.exe: build/lua
	make -C $< PLAT=mingw CC=$(WINCC) -j$(nproc)

build/lua/src/liblua.dll.a: build/lua/src/lua.exe
	x86_64-w64-mingw32-gcc -shared -o build/lua/src/lua54.dll build/lua/src/*.o -Wl,--out-implib,$@

clean:
	rm build -rf

.PHONY: default clean
