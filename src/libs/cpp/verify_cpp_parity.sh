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

# Make sure that all functions have a cpp implementation (except synonym funcs)
failed=0
while read -r i; do
    if [ ! -e functions/"$i".cpp ]; then
        >&2 echo -e "\e[1;31mERROR:\e[0m Missing C++ implementation of \`$i\` function."
        failed=1
    fi
done < <($cmd --introspect --functions --synonyms=none)

# Make sure that all actions have a cpp implementation
failed=0
for i in ../../runtime/actions/*.lua; do
    i=${i%*.lua}
    i=$(basename "$i")
    if [ ! -e actions/"$i".cpp ]; then
        >&2 echo -e "\e[1;31mERROR:\e[0m Missing C++ implementation of \`$i\` action."
        failed=1
    fi
done

exit $failed
