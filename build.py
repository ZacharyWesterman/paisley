#!/usr/bin/env python3

import re
from pathlib import Path
from sys import argv
import subprocess

require = re.compile(r'require +[\'"]([^\'"]+)[\'"]')
debug = re.compile(
    r'--\[\[minify-delete\]\].*?--\[\[/minify-delete\]\]', re.DOTALL)
debug2 = re.compile(
    r'(--\[\[build-replace=([^\]]+)\]\].*?--\[\[/build-replace\]\])', re.DOTALL)
# comment = re.compile(r'(?<![\'"-])--(\[\[([^\]]|\](?!\]))*\]\]|[^\n]*)')
# endline = re.compile(r'\n\n+')
# spaces  = re.compile(r'[ \t]+\n')
# indents = re.compile(r'\n[ \t]+')

comment1 = re.compile(r'--.*')
comment2 = re.compile(r'(?s)--\[\[.+?\]\]')
keyword = re.compile(r'\w+')
operator = re.compile(r'[^\s\w\'"]+')
string1 = re.compile(r'\'(\\.|[^\'])*\'')
string2 = re.compile(r'"(\\.|[^"])*"')
whitespace = re.compile(r'(?s)\s+')


class Action:
    PAD = 0
    NOPAD = 1
    IGNORE = 2


PATTERNS = (
    (comment2, Action.IGNORE),
    (comment1, Action.IGNORE),
    (string1, Action.NOPAD),
    (string2, Action.NOPAD),
    (keyword, Action.PAD),
    (operator, Action.NOPAD),
    (whitespace, Action.IGNORE),
)

build_dir = '.paisley-build' if '--tempdir' in argv else 'build'

Path(f'{build_dir}/').mkdir(exist_ok=True)
dir = Path('/tmp')
if not dir.exists():
    dir = Path('.')

if '--fetch-srlua' in argv:
    if not (dir / 'paisley-build-srlua').exists():
        subprocess.call(['git', 'clone', 'https://github.com/LuaDist/srlua.git', f'{dir}/paisley-build-srlua'])

    if not (dir / 'paisley-build-srlua/build/glue').exists():
        (dir / 'paisley-build-srlua/build').mkdir(exist_ok=True)
        subprocess.call(['cmake', f'-B{dir}/paisley-build-srlua/build', f'-S{dir}/paisley-build-srlua'])
        subprocess.call(['make', '-C', f'{dir}/paisley-build-srlua/build'])

VERSION = open('version.txt', 'r').readline().strip()


def minify(lua_source: str) -> str:
    result = ''
    while len(lua_source):
        matched = False
        for (pattern, action) in PATTERNS:
            if m := pattern.match(lua_source):
                matched = True

                text = m.group(0)
                lua_source = lua_source[len(text):]

                if action == Action.PAD:
                    result += text + ' '
                elif action == Action.NOPAD:
                    if len(result) and result[-1] == ' ':
                        result = result[0:-1] + text
                    else:
                        result += text
                break

        if not matched:
            print('ERROR: found unexpected char: ', lua_source[0])
            exit(1)
            lua_source = lua_source[1::]

    if len(result) and result[-1] == ' ':
        result = result[0:-1]

    return result


def generate_full_source(filename: str, remove_debug: bool) -> str:
    if '--quiet' not in argv:
        print('Building ' + filename + '...')

    with open(filename, 'r') as fp:

        text = fp.read()

        while m := require.search(text):
            fname = m[1].replace('.', '/') + '.lua'
            with open(fname, 'r') as fp2:
                text = text[0:m.start(0)] + fp2.read() + text[m.end(0)::]

        if remove_debug:
            # Remove all blocks that are marked with debug sections
            text = debug.sub('', text)

        # Replace certain blocks with the contents of a file
        for i in debug2.findall(text):
            t = i[1]
            if t.startswith('build/'):
                t = build_dir + '/' + i[1][6:]

            with open(t, 'r') as subfile:
                subtext = subfile.read().strip().replace('\\', '\\\\').replace('\r', '').replace('\n', '\\n').replace('"', '\\"')
                # if remove_debug:
                # 	subtext = subtext.replace('--', '@@@')
                text = text.replace(i[0], '"' + subtext + '"')

        if remove_debug:
            return minify(text)

        return text


# Allow only generating specific files.
files = ['compiler.lua', 'runtime.lua', 'paisley']
if any(i in argv for i in ['compiler', 'runtime', 'paisley', 'standalone']):
    files = []

if 'compiler' in argv:
    files += ['compiler.lua']
if 'runtime' in argv:
    files += ['runtime.lua']
if 'paisley' in argv or 'standalone' in argv:
    files += ['paisley']

# Build the Plasma version of the Paisley engine
for i in ['compiler.lua', 'runtime.lua']:
    if i not in files:
        continue

    text = generate_full_source(f'src/{i}', True)
    module = i.split('.')[0]
    prefix = f'--[[Paisley {module} v{VERSION}, written by SenorCluckens]]\n--[[This build has been minified to reduce file size]]\n'

    with open(f'{build_dir}/{i}', 'w') as out:
        out.write(prefix + text)

if 'paisley' in files:
    # Build the desktop version of the Paisley engine
    text = generate_full_source('paisley', False)
    with open(f'{build_dir}/paisley_standalone.lua', 'w') as out:
        out.write(text)
