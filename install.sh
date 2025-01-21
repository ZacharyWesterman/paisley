#!/usr/bin/env bash
FAILED=0

if ! which lua &>/dev/null
then
	>&2 echo 'ERROR: Lua is not installed! Please install it and try again.'
	FAILED=1
elif ! which luac &>/dev/null
then
	>&2 echo 'ERROR: Lua is installed, but `luac` is not! Please install it and try again.'
	FAILED=1
fi

if ! which python3 &>/dev/null
then
	>&2 echo 'ERROR: Python 3 is not installed! Please install it and try again.'
	FAILED=1
fi

if ! which luarocks &>/dev/null
then
	>&2 echo 'WARNING: `luarocks` is not installed, so dependencies cannot be installed either. Some features may be missing from this build.'
fi

[ $FAILED == 1 ] && exit 1

#Make sure we're in the same dir as this script.
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

#Package the program into Lua bytecode
python3 build.py || exit 1
python3 build.py --fetch-srlua || exit 1
luac -o build/paisley.luac build/paisley_standalone.lua || exit 1

#Build the standalone executable
srluadir='/tmp/paisley-build-srlua/build'
"$srluadir/glue" "$srluadir/srlua" build/paisley.luac build/paisley || exit 1
chmod +x build/paisley || exit 1

rm -f "$HOME/.local/bin/paisley"
mv build/paisley "$HOME/.local/bin/paisley"
rsync -a stdlib "$HOME/.local/bin/"
rm build -rf

install_dependency()
{
	sudo luarocks install "$1" &>/dev/null
}

wait_on_process()
{
	local pid=$1
	local dep=$2
	local item=$3
	local total=$4

	local spin='-\|/'
	local i=0
	while kill -0 $pid 2>/dev/null
	do
		i=$(((i+1)%4))
		printf "\r[%d/%d] Installing dependency \`%s\`... %s" $item $total "$dep" "${spin:$i:1}"
		sleep .1
	done
	printf '\r\e[K'
}

echo 'Requesting permission to install dependencies...'

total="$(<requires.txt wc -l)"
item=0
while read rock name
do
	item=$((item + 1))

	#Check if rock is already installed. If not, install it.
	if [ "$(lua <<< "x, _ = pcall(require, '$name') print(x)")" != true ]
	then
		#Prompt once for password
		if ! sudo echo -n
		then
			>&2 echo 'WARNING: Failed to install dependencies: user permission denied.'
			>&2 echo '         It will still work, but some features may be missing.'
			break
		fi

		( install_dependency "$rock" ) &
		wait_on_process $! "$rock" $item $total
	fi
done < requires.txt

echo 'Paisley is now installed.'
