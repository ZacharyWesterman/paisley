#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

mkdir -p build/plasma

echo -e "\e[1;32mBuilding Compiler...\e[0m"
./paisley --plasma-build=compiler -o build/plasma/compiler.lua

echo -e "\e[1;32mBuilding Runtime...\e[0m"
./paisley --plasma-build=runtime -o build/plasma/runtime.lua

echo -e "\e[1;32mDone!\e[0m"
echo "Compiler and runtime are under $(dirname "${BASH_SOURCE[0]}")/build/plasma/"
