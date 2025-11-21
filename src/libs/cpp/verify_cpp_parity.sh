#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

cmd=./../../../paisley
if [ ! -e "$cmd" ]; then
	if ! which paisley &>/dev/null; then
		# Paisley isn't installed on this system;
		# No way to verify
		exit 0
	fi

	cmd=paisley
fi

# Make sure that all functions have a cpp implementation
$cmd --introspect --functions | while read -r i; do
	if [ ! -e functions/"$i".cpp ]; then
		>&2 echo -e "\e[1;31mERROR:\e[0m Missing C++ implementation of \`$i\` function."
		exit 1
	fi
done
