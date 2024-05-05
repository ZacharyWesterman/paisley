#!/usr/bin/env bash
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm -f "$HOME/.local/bin/paisley"
ln -s "$DIR/paisley" "$HOME/.local/bin/paisley"

# for i in luasocket luafilesystem
# do
# 	sudo luarocks install $i
# done
