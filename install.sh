#!/usr/bin/env bash
ln -s "$HOME/.local/bin/paisley" "$(dirname "${BASH_SOURCE[0]}")/paisley"
sudo luarocks install socket luafilesystem
