#!/usr/bin/env bash
FAILED=0

if ! which lua &>/dev/null; then
	echo >&2 'ERROR: Lua is not installed! Please install it and try again.'
	FAILED=1
elif ! which luac &>/dev/null; then
	echo >&2 'ERROR: Lua is installed, but `luac` is not! Please install it and try again.'
	FAILED=1
fi

if ! which python3 &>/dev/null; then
	echo >&2 'ERROR: Python 3 is not installed! Please install it and try again.'
	FAILED=1
fi

if ! which luarocks &>/dev/null; then
	echo >&2 'WARNING: `luarocks` is not installed, so dependencies cannot be installed either. Some features may be missing from this build.'
fi

[ $FAILED == 1 ] && exit 1

#Make sure we're in the same dir as this script.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

#Package the program into Lua bytecode
echo 'Building Paisley...'
python3 build.py --fetch-srlua --tempdir --quiet || exit 1
luac -o .paisley-build/paisley.luac .paisley-build/paisley_standalone.lua || exit 1

#Build the standalone executable
srluadir='/tmp/paisley-build-srlua/build'
"$srluadir/glue" "$srluadir/srlua" .paisley-build/paisley.luac .paisley-build/paisley || exit 1
chmod +x .paisley-build/paisley || exit 1

rm -f "$HOME/.local/bin/paisley"
mv .paisley-build/paisley "$HOME/.local/bin/paisley"
rsync -a stdlib "$HOME/.local/bin/"
rm .paisley-build -rf

install_dependency() {
	sudo luarocks install "$1" &>/dev/null
}

wait_on_process() {
	local pid=$1
	local dep=$2
	local item=$3
	local total=$4

	local spin='-\|/'
	local i=0
	while kill -0 $pid 2>/dev/null; do
		i=$(((i + 1) % 4))
		printf "\r[%d/%d] Installing dependency \`%s\`... %s" $item $total "$dep" "${spin:$i:1}"
		sleep .1
	done
	printf '\r\e[K'
}

echo 'Requesting permission to install dependencies...'

#Prompt once for password
if ! sudo echo -n; then
	echo >&2 'WARNING: Failed to install dependencies: user permission denied.'
	echo >&2 '         It will still work, but some features may be missing.'
else
	total="$(wc <requires.txt -l)"
	item=0
	while read rock name; do
		item=$((item + 1))

		#Check if rock is already installed. If not, install it.
		if [ "$(lua <<<"x, _ = pcall(require, '$name') print(x)")" != true ]; then
			(install_dependency "$rock") &
			wait_on_process $! "$rock" $item $total
		fi
	done <requires.txt
fi

echo 'Paisley is now installed.'
