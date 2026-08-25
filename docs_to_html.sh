#!/usr/bin/env bash

if ! command -v pandoc &>/dev/null; then
	echo >&2 "Error: \`pandoc\` not installed. To use this script, install pandoc through your package manager."
	exit 1
fi

lua build_docs.lua

rm -rf html
mkdir html
cp images/paisley-logo-small.png html/logo.png

find docs/* -type d | while read -r dir; do
	dir=${dir/docs/html}
	mkdir "$dir"
	cp images/paisley-logo-small.png "$dir/logo.png"
done

# Automatically convert .md links into .html
echo "function Link(el)
	el.target = string.gsub(el.target, '%.md', '.html')
	return el
end" > .filter.lua

wait

while read -r file; do
	tofile=${file/docs/html}
	tofile=${tofile/.md/.html}
	[ "$file" == 'README.md' ] && tofile='html/index.html'

	csspath="$(dirname "${tofile/html\//}" | sed -E 's|\w[^/]*|..|g')/style.css"
	pandoc -f markdown -t html5 "$file" --css "$csspath" -s \
		--lua-filter=.filter.lua --metadata title="Paisley Documentation" -V title:"" \
		--highlight-style breezedark --syntax-definition pandoc_syntax_definition.xml \
	| sed -E 's|images/paisley-logo-small.png|logo.png|g' \
	> "$tofile" &
done < <(find README.md docs -type f -name '*.md')
wait

find docs -type f -not -name '*.md' | while read -r file; do
	cp "$file" "${file/docs/html}"
done

rm -f .filter.lua .syntax.xml
