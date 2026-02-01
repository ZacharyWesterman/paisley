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

error() {
    >&2 echo -e "[\e[31mERROR\e[0m]: $*"
    failed=1
}

strip() {
    local i
    for i in "$@"; do
        basename "${i%.*}"
    done
}

readarray -t a1 < <($cmd --introspect --functions --synonyms=none)
a2=(
    add
    arrayindex
    arrayslice
    bitwise_and
    bitwise_not
    bitwise_or
    bitwise_xor
    booland
    boolnot
    boolor
    boolxor
    concat
    div
    env_get
    equal
    explode
    greater
    greaterequal
    implode
    inarray
    jump
    jumpiffalse
    jumpifnil
    length
    less
    lessequal
    mul
    notequal
    pow
    rem
    strlike
    sub
    superimplode
    varexists
)

declare -A func_list
declare -A operators

for i in "${a1[@]}"; do func_list["$i"]=1; done
for i in "${a2[@]}"; do operators["$i"]=1; done

# Make sure that all functions have a cpp implementation (except synonym funcs)
failed=0
for i in "${!func_list[@]}"; do
    if [ ! -e functions/"$i".cpp ]; then
        error "Missing C++ implementation of \`$i\` function."
    fi
done

# Make sure that there are no cpp functions that aren't implemented in Lua.
while read -r i; do
    if [ "${operators["$i"]}" != '' ]; then continue; fi
    if [ "${func_list["$i"]}" == '' ]; then
        error "C++ implementation of \`$i\` function exists but no such Lua function was found."
    fi
done < <(strip functions/*.cpp)

# Make sure that all Lua actions have a cpp implementation
while read -r i; do
    if [ ! -e actions/"$i".cpp ]; then
        error "Missing C++ implementation of \`$i\` action."
    fi
done < <(strip ../../runtime/actions/*.lua)

# Make sure that all cpp actions have a Lua implementation
while read -r i; do
    if [ "$i" != pop_catch_or_throw ] && [ ! -e ../../runtime/actions/"$i".lua ]; then
        error "C++ implementation of \`$i\` action exists but no such Lua action was found."
    fi
done < <(strip actions/*.cpp)

exit $failed
