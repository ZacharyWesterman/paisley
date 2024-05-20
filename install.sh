#!/usr/bin/env bash
if ! which lua &>/dev/null
then
	>&2 echo 'ERROR: Lua is not installed! Please install Lua and try again.'
	exit 1
fi

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm -f "$HOME/.local/bin/paisley"
ln -s "$DIR/paisley" "$HOME/.local/bin/paisley"

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

total="$(<requires.txt wc -l)"
item=0
while read rock name
do
	item=$((item + 1))

	#Check if rock is already installed. If not, install it.
	if [ "$(lua <<< "x, _ = pcall(require, '$name') print(x)")" != true ]
	then
		sudo echo -n #prompt once for password
		( install_dependency "$rock" ) &
		wait_on_process $! "$rock" $item $total
	fi
done < requires.txt

echo 'Paisley is now installed.'
