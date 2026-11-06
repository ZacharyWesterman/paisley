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

# Automatically convert .md and .l links into .html
echo "function Link(el)
	el.target = el.target:gsub('%.md', '.html'):gsub('%.l', '.html')
	return el
end" > .filter.lua

wait

# Convert syntax file into a markdown document.
echo "# Paisley Syntax

This is the full syntax specification for the Paisley language.
It's written in an ad-hoc format, not any real parser-generator syntax;
the actual parser itself is hand-written.
Instead, the hope here is that this file will make operator precedence &
how statements are parsed more clear to the reader.

---

\`\`\`
$(cat docs/syntax.l)
\`\`\`

---

### [Back](walkthrough.md)
" > docs/syntax.md


# Convert example scripts into temporary markdown documents,
# and generate examples index.
echo >&2 "Building examples..."
mkdir -p docs/examples html/examples
echo "# Examples
" > docs/examples.md
prevtext=''
prevfile=''
while read -r file; do
	mdfile="docs/examples/$(basename "${file/.pai/.md}")"
	if [ "$prevfile" != '' ]; then
		sed -i "s/~next~/ | [Next >]($(basename "$mdfile"))/g" "$prevfile"
	fi

	echo "# $(basename "$file")

### ${prevtext}[Back](../examples.md)~next~

---

\`\`\`pai
$(cat "$file")
\`\`\`

---

### ${prevtext}[Back](../examples.md)~next~
" > "$mdfile"
	echo "- [${file/examples\//}](${mdfile})" >> docs/examples.md

	prevtext="[< Prev]($(basename "$mdfile")) | "
	prevfile=$mdfile
done < <(find examples -type f -name '*.pai' | sort)
[ "$prevfile" != '' ] && sed -i "s/~next~//g" "$prevfile"


# Convert all markdown files to HTML docs
echo >&2 "Converting to HTML..."
while read -r file; do
	fromfile=${file}
	tofile=${file/docs/html}
	tofile=${tofile/.md/.html}
	if [ "$file" == 'README.md' ]; then
		tofile='html/index.html'
		fromfile='.README.md'
		sed 's/Language Walkthrough/Examples](examples.md) | [Language Walkthrough/g' "$file" \
		| sed 's|\[examples/\]([^\)]*)|[examples/](examples.md)|g' > "$fromfile"
	fi

	csspath="$(dirname "${tofile/html\//}" | sed -E 's|\w[^/]*|..|g')/style.css"
	pandoc -f markdown -t html5 "$fromfile" --css "$csspath" -s \
		--lua-filter=.filter.lua --metadata title="Paisley Documentation" -V title:"" \
		--highlight-style breezedark --syntax-definition pandoc_syntax_definition.xml \
	| sed -E 's|images/paisley-logo-small.png|logo.png|g' \
	| sed -E 's|href="docs/|href="|g' \
	| sed -E 's|<body>|<body><a class="logo" href="/paisley"></a>|g' \
	> "$tofile" &
done < <(find README.md docs -type f -name '*.md')
wait

echo >&2 "Finalizing..."

# Remove example scripts from temporary markdown documents
rm docs/examples docs/examples.md docs/syntax.md .README.md -rf

# Just copy over any non-markdown files.
find docs -type f -not -name '*.md' | while read -r file; do
	cp "$file" "${file/docs/html}"
done

rm -f .filter.lua .syntax.xml
