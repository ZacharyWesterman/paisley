#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Make sure that all functions have a cpp implementation
./../../../paisley --introspect --functions | while read -r i; do
	if [ ! -e functions/"$i".cpp ]; then
		>&2 echo -e "\e[1;31mERROR:\e[0m Missing C++ implementation of \`$i\` function."
		exit 1
	fi
done
