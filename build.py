import re
from pathlib import Path

require = re.compile(r'require *[\'"]([^\'"]+)[\'"]')
comment = re.compile(r'(?<![\'"-])--(\[\[([^\]]|\](?!\]))*\]\]|[^\n]*)')
endline = re.compile(r'\n\n+')
spaces  = re.compile(r'[ \t]+\n')
indents = re.compile(r'\n[ \t]+')

Path('build/').mkdir(exist_ok=True)

for i in ['compiler.lua', 'runtime.lua']:
	with open('src/'+i, 'r') as fp:
		text = fp.read()

		while m := require.search(text):
			fname = m[1].replace('.', '/') + '.lua'
			with open(fname, 'r') as fp2:
				text = text[0:m.start(0)] + fp2.read() + text[m.end(0)::]

		#Remove all lua comments from generated source (minimize file size)
		text = comment.sub('', text)
		#Minimize extra white space
		text = spaces.sub('\n', text)
		text = endline.sub('\n', text)
		# text = indents.sub('\n', text)

		with open('build/'+i, 'w') as out:
			out.write(text)
