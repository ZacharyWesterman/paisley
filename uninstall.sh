#!/usr/bin/env bash
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm -f "$HOME/.local/bin/paisley"

uninstall_dependency()
{
	sudo luarocks remove "$1" &>/dev/null
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
		printf "\r[%d/%d] Removing dependency \`%s\`... %s" $item $total "$dep" "${spin:$i:1}"
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
	if [ "$(lua <<< "x, _ = pcall(require, '$name') print(x)")" == true ]
	then
		sudo echo -n #prompt once for password
		( uninstall_dependency "$rock" ) &
		wait_on_process $! "$rock" $item $total
	fi
done < requires.txt

echo 'Paisley has been removed from your system.'
