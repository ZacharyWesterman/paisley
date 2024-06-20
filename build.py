#!/usr/bin/env python3

import re
from pathlib import Path

require = re.compile(r'require +[\'"]([^\'"]+)[\'"]')
debug   = re.compile(r'--\[\[minify-delete\]\].*?--\[\[/minify-delete\]\]', re.DOTALL)
debug2  = re.compile(r'(--\[\[build-replace=([^\]]+)\]\].*?--\[\[/build-replace\]\])', re.DOTALL)
comment = re.compile(r'(?<![\'"-])--(\[\[([^\]]|\](?!\]))*\]\]|[^\n]*)')
endline = re.compile(r'\n\n+')
spaces  = re.compile(r'[ \t]+\n')
indents = re.compile(r'\n[ \t]+')

Path('build/').mkdir(exist_ok=True)

VERSION = open('version.txt', 'r').readline().strip()

def generate_full_source(filename: str, remove_debug: bool) -> str:
	with open(filename, 'r') as fp:

		text = fp.read()

		while m := require.search(text):
			fname = m[1].replace('.', '/') + '.lua'
			with open(fname, 'r') as fp2:
				text = text[0:m.start(0)] + fp2.read() + text[m.end(0)::]

		if remove_debug:
			#Remove all blocks that are marked with debug sections
			text = debug.sub('', text)

		#Replace certain blocks with the contents of a file
		for i in debug2.findall(text):
			with open(i[1], 'r') as subfile:
				subtext = subfile.read().strip().replace('\r', '').replace('\n', '\\n').replace('"', '\\"')
				if remove_debug:
					subtext = subtext.replace('--', '@@@')
				text = text.replace(i[0], '"' + subtext + '"')

		if remove_debug:
			#Make sure that non-comment dashes don't get removed
			text = text.replace('`--', '`@@@').replace("'--", "'@@@").replace('----', '@@@@@@')

			#Remove all lua comments from generated source (minimize file size)
			text = comment.sub('', text)
			#Minimize extra white space
			text = spaces.sub('\n', text)
			text = endline.sub('\n', text)
			text = indents.sub('\n', text)

			#Put back non-comment dashes
			text = text.replace('@@@', '--')

		return text

#Build the Plasma version of the Paisley engine
for i in ['compiler.lua', 'runtime.lua']:
	text = generate_full_source(f'src/{i}', True)
	module = i.split('.')[0]
	prefix = f'--[[Paisley {module} v{VERSION}, written by SenorCluckens]]\n--[[This build has been minified to reduce file size]]'

	with open('build/'+i, 'w') as out:
		out.write(prefix + text)

#Build the desktop version of the Paisley engine
text = generate_full_source('paisley', False)
with open('build/paisley_standalone.lua', 'w') as out:
	out.write(text)
