#!/usr/bin/env bash
rm -f "$HOME/.local/bin/paisley"
ln -s "$(dirname "${BASH_SOURCE[0]}")/paisley" "$HOME/.local/bin/paisley"

for i in luasocket luafilesystem
do
	sudo luarocks install $i
done
