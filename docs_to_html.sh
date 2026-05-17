#!/usr/bin/env bash

if ! command -v pandoc &>/dev/null; then
	echo >&2 "Error: \`pandoc\` not installed. To use this script, install pandoc through your package manager."
	exit 1
fi

rm -rf html
mkdir html
cp images/paisley-logo-small.png html/logo.png

find docs/* -type d | while read dir; do
	dir=${dir/docs/html}
	mkdir "$dir"
	cp images/paisley-logo-small.png "$dir/logo.png"
done

# Automatically convert .md links into .html
echo "function Link(el)
	el.target = string.gsub(el.target, '%.md', '.html')
	return el
end" > .filter.lua

while read file; do
	tofile=${file/docs/html}
	tofile=${tofile/.md/.html}
	csspath="$(dirname "${tofile/html\//}" | sed -E 's|\w[^/]*|..|g')/style.css"
	pandoc -f markdown -t html5 "$file" --css "$csspath" -s \
		--lua-filter=.filter.lua --metadata title="Paisley Documentation" -V title:"" \
		--highlight-style zenburn --syntax-definition pandoc_syntax_definition.xml \
	> "$tofile" &
done < <(find docs -type f -name '*.md')
wait

find docs -type f -not -name '*.md' | while read file; do
	cp "$file" "${file/docs/html}"
done

rm -f .filter.lua
