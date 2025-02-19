#!/usr/bin/env bash

#Make sure we're in the same dir as this script.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

if [ -z "$1" ]; then
	echo "This script creates a new call code function."
	echo "Usage: $0 <function_name>"
	exit 1
fi

cpptext="#include \"$1.hpp\"

void $1(Context &context) noexcept
{
	(void)context;
}"

hpptext="#pragma once

#include \"../context.hpp\"

void $1(Context &) noexcept;"

if [ ! -e "$1.cpp" ]; then
	echo "$cpptext" >"$1.cpp"
fi

if [ ! -e "$1.hpp" ]; then
	echo "$hpptext" >"$1.hpp"
fi
