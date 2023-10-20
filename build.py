import re
from pathlib import Path

require = re.compile(r'require *[\'"]([^\'"]+)[\'"]')
Path('build/').mkdir(exist_ok=True)

for i in ['main.lua', 'runtime.lua']:
	with open(i, 'r') as fp:
		text = fp.read()

		while m := require.search(text):
			fname = m[1] + '.lua'
			with open(fname, 'r') as fp2:
				text = text[0:m.start(0)] + fp2.read() + text[m.end(0)::]

		with open('build/'+i, 'w') as out:
			out.write(text)
