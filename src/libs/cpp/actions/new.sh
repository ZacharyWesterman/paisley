#!/usr/bin/env bash

#Make sure we're in the same dir as this script.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

if [ -z "$1" ]; then
	echo "This script creates a new action function."
	echo "Usage: $0 <function_name>"
	exit 1
fi

cpptext="#include \"$1.hpp\"

void $1(VirtualMachine &vm) noexcept
{
	(void)vm;
}"

hpptext="#pragma once

#include \"../virtual_machine.hpp\"

void $1(VirtualMachine &) noexcept;"

if [ ! -e "$1.cpp" ]; then
	echo "$cpptext" >"$1.cpp"
fi

if [ ! -e "$1.hpp" ]; then
	echo "$hpptext" >"$1.hpp"
fi
