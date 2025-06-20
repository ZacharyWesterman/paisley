#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

mkdir -p build

# Build for this platform (assume Linux)
echo -e "\e[1;32mBuilding for Linux...\e[0m"
./paisley --compile-self=gcc --output=build/paisley
echo

# Build for Windows
echo -e "\e[1;32mBuilding for Windows...\e[0m"
./paisley --compile-self=x86_64-w64-mingw32-gcc --output=build/paisley.exe
