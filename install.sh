#!/usr/bin/env bash
FAILED=0

if ! command -v lua &>/dev/null; then
	echo >&2 -e '\e[31mERROR\e[0m: Lua is not installed! Please install it and try again.'
	echo >&2 'On Ubuntu, this would be `apt install lua5.3 liblua5.3-dev luarocks`.'
	FAILED=1
fi

#Make sure Lua version is at least 5.3
if ! command -v lua5.3 &>/dev/null && ! command -v lua53 &>/dev/null && ! command -v lua5.4 &>/dev/null && ! command -v lua54 &>/dev/null; then
	echo >&2 -e '\e[31mERROR\e[0m: Lua version 5.3 or higher is required to install Paisley.'
	FAILED=1
fi

if ! command -v luarocks &>/dev/null; then
	echo >&2 -e '\e[33mWARNING\e[0m: luarocks is not installed, so optional dependencies cannot be installed either.'
	echo >&2 '         Paisley will still work, but some quality-of-life features will be missing.'
fi

[ $FAILED == 1 ] && exit 1

#Make sure we're in the same dir as this script.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

#Make sure user is running as root
if [ "$EUID" -ne 0 ]; then
	echo >&2 -e '\e[31mERROR\e[0m: This script must be run as root. Aborting install.'
	exit 1
fi

#Package the program into an executable and install it.
./paisley --install "$@" || exit 1

install_dependency() {
	local rock_name
	local version
	local failed
	rock_name="$1"

	local valid_versions=()
	if command -v lua5.3 &>/dev/null || command -v lua53 &>/dev/null; then
		valid_versions+=(5.3)
	fi
	if command -v lua5.4 &>/dev/null || command -v lua54 &>/dev/null; then
		valid_versions+=(5.4)
	fi

	#Try to install both versions, 5.3 and 5.4, in case one fails.
	for version in "${valid_versions[@]}"; do
		# Only install the rock if it's not already installed.
		if luarocks list --lua-version $version "$rock_name" 2>/dev/null | grep "$rock_name" &>/dev/null; then continue; fi
		sudo luarocks --lua-version $version install "$rock_name" &>/dev/null

		if ! luarocks list --lua-version $version "$rock_name" 2>/dev/null | grep "$rock_name" &>/dev/null; then
			echo >&2 -e "\r\e[31mERROR\e[0m: Failed to install rock \"$rock_name\" for Lua $version!"
		fi
	done
}

wait_on_process() {
	local pid=$1
	local dep=$2
	local item=$3
	local total=$4

	local spin='-\|/'
	local i=0
	while kill -0 "$pid" 2>/dev/null; do
		i=$(((i + 1) % 4))
		printf "\r[%d/%d] Installing dependency \`%s\`... %s" "$item" "$total" "$dep" "${spin:$i:1}"
		sleep .1
	done
	printf '\r\e[K'
}

echo
echo -n 'Installing Lua rocks...'

#Prompt once for password
if ! sudo echo -n; then
	echo ' Failed.'
	echo >&2 -e '\e[33mWARNING\e[0m: Failed to install dependencies: user permission denied.'
	echo >&2 '         It will still work, but some features may be missing.'
elif command -v luarocks &>/dev/null; then
	total="$(wc <requires.txt -l)"
	item=0
	while read -r rock name; do
		item=$((item + 1))

		#Check if rock is already installed. If not, install it.
		if [ "$(lua <<<"x, _ = pcall(require, '$name') print(x)")" != true ]; then
			(install_dependency "$rock") &
			wait_on_process $! "$rock" "$item" "$total"
		fi
	done <requires.txt
	printf '\rInstalling Lua rocks... Done.\n'
fi

echo
echo -e '\e[32mPaisley is now installed and ready to use.\e[0m'
