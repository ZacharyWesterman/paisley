#!/usr/bin/env python3

import requests

response = requests.get(
    'https://raw.githubusercontent.com/' +
    'ZacharyWesterman/paisley-vscode/refs/heads/' +
    'main/syntaxes/paisley.tmLanguage.json',
    timeout=10
)

if response.status_code >= 300 or response.status_code < 200:
    raise requests.RequestException('Failed to fetch JSON syntax file.')


class BuildError(Exception):
    ...


def escape(text: str) -> str:
    cleaned = text.replace('&', '&amp;').replace('"', '&quot;').replace(
        '<', '&lt;').replace('>', '&gt;').replace('\t', '\\t')

    # Can't handle case-insensitive regex?
    cleaned = cleaned.replace('(?i)', '')
    return cleaned


attributes = {
    'keyword': 'dsKeyword',
    'comment': 'dsComment',
    'Paisley': 'dsNormal',
}


def attr_from_name(name: str) -> str:
    # TODO: convert from vscode names (e.g. `keyword.control.paisley`) to attribute names
    name = name.replace('.paisley', '').split('.')
    this_attr = attributes
    current_attr = 'dsNormal'
    for part in name:
        if type(this_attr) is str or part not in this_attr:
            break
        this_attr = this_attr[part]

    return current_attr


def context_from_name(parent_name: str, index_in_parent: int) -> str:
    return f'{parent_name}_{index_in_parent}'


def build_context_link(parent_name: str, config: dict, index_in_parent: int) -> str:
    if icl := config.get('include'):
        icl = escape(icl.replace('#', ''))
        return f'  <IncludeRules context="{icl}" />\n'

    name = config.get('name', '')
    name_attr = attr_from_name(name)
    name_context = context_from_name(parent_name, index_in_parent)

    if pattern := config.get('match'):
        pattern = escape(pattern)
        return f'  <RegExpr String="{pattern}" attribute="{name_attr}" />\n'

    if pattern := config.get('begin'):
        pattern = escape(pattern)
        return f'  <RegExpr String="{pattern}" attribute="{name_attr}" context="{name_context}" />\n'

    raise BuildError(f'Could not build context link for: {config}')


def build_linked_context(parent_name: str, config: dict, index_in_parent: int) -> str:
    if config.get('include'):
        return ''

    name_context = context_from_name(parent_name, index_in_parent)

    if config.get('match'):
        return ''

    if config.get('begin'):
        return build_context(f'{name_context}', config)

    return ''


def build_context(ident: str | None, config: dict) -> None:
    context_name = ident if ident is not None else 'Normal'
    context_style = config.get('name')
    line_end_context = '#pop' if config.get('end') == '$' else '#stay'

    text = f'<context name="{context_name}" lineEndContext="{line_end_context}"'
    if context_style is not None:
        text += f' attribute="{attr_from_name(context_style)}"'
    text += '>\n'

    if beg_pattern := config.get('begin'):
        text += f'  <RegExpr String="{escape(beg_pattern)}" context="{context_name}_inner"'
        if context_style is not None:
            text += f' attribute="{attr_from_name(context_style)}"'
        text += ' />\n</context>\n'
        text += f'<context name="{context_name}_inner" lineEndContext="{line_end_context}"'
        if context_style is not None:
            text += f' attribute="{attr_from_name(context_style)}"'
        text += '>\n'

    for (i, rule) in enumerate(config.get('patterns', [])):
        text += build_context_link(context_name, rule, i)

    if end_pattern := config.get('end'):
        if end_pattern != '$':
            end_pattern = escape(end_pattern)
            text += f'  <RegExpr String="{end_pattern}" context="#pop"'
            if context_style is not None:
                text += f' attribute="{attr_from_name(context_style)}"'
            text += ' />\n'

    text += '  <DetectSpaces context="#stay" attribute="dsNormal" />\n'
    text += '</context>\n'

    for (i, rule) in enumerate(config.get('patterns', [])):
        text += build_linked_context(context_name, rule, i)

    return text


vscode_rules = response.json()
text = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE language>
<language name="Paisley" section="Scripts" version="1" kateversion="2.4"
    extensions="*.pai;*.paisley" mimetype="application/pai;application/paisley"
    author="Zachary Westerman (westerman.zachary@gmail.com)" license="GPL3"
>
<highlighting>
<contexts>
'''
text += build_context(None, vscode_rules)

for (name, rule) in vscode_rules.get('repository').items():
    text += build_context(name, rule)

text += '\n</contexts>'

text += '''
</highlighting>
</language>
'''

print(text.strip())
