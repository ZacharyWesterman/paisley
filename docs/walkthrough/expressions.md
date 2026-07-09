## Expressions:
First and foremost, expressions will only be evaluated inside curly braces, `{}`. If you place an expression outside of braces, it will be treated as plain text. For example `print {1+2}` will print "3" but `print 1+2` will print the actual string "1+2".

Expressions can be placed anywhere inside a command or statement operand. In addition, they can also be placed inside double-quoted strings (e.g. `"a = {1+2}"` gives `a = 3`) to perform easy string interpolation. Note that single-quoted strings **do not** interpolate expressions, so for example `'a = {1+2}'` would give exactly `a = {1+2}` without parsing any expression.

### Allowed values:
- Hexadecimal numbers, `0xFFFF`
- Octal numbers, `0c7777`
- Binary numbers, `0b1111`
- Decimal numbers, `1.2345` or `12345` or `1_000_000`. Note that underscores are ignored by the compiler, you can use them for readability purposes.
- Booleans, `true` or `false`
- `null`, equivalent to Lua's "nil"
- Strings with interpolation allowed, `"some text"`
- Strings with NO interpolation, `'some text'`
- Multi-line strings with interpoation, `"""some text"""`
- Multi-line strings with NO interpolation, `'''some text'''`
- Variables, `var_name`, `x`, etc.
- `@`, the "parameter list" variable, an array containing any values passed to the current function. If used outside of a function, it instead contains any arguments passed to the script.
- `$`, the "command list" variable, an array containing the names of all the commands the current script has access to.
- `_VARS`, the "variables" variable, an object that contains the names and values of all variables in the current script as key-value pairs.
- `_VERSION`, the "version number" variable, a string formatted as `MAJOR.MINOR.PATCH`.
- `_ENV`, the "environment variables" variable, an object that reads an environment variable when indexed. Note that unlike other variables, only individual keys of `_ENV` are allowed to be accessed, not the entire object.
- Arrays, e.g. `(1,2,3,4,5)`. See [the docs for details](arrays.md).
- Objects, e.g. `("a" => 1, "b" => 2)`. See [the docs for details](objects.md).

### Escape sequences:

If you would like to avoid interpolation in double-quoted strings, simply escape the opening curly brace with a backslash, e.g.
```pai
print "the expression \{1+2} evaluates to {1+2}"
print "you can also put \"quotes\" and line breaks (\n) inside strings!"
```

There are a few special escape sequences:

- `\n` outputs a line ending.
- `\t` outputs a tab.
- `\r` outputs a carriage return.
- `\v` outputs a vertical tab.
- `\"` outputs a double quote.
- `\'` outputs a single quote.
- `\{` outputs a left curly brace.
- `\}` outputs a right curly brace.
- `\ ` (backslash + space) outputs a non-breaking space.
- `\x` followed by any 2 hexadecimal digits outputs the respective byte.
- `\u` followed by any 4 hexadecimal digits outputs the respective Unicode character.
- `\U` followed by any 8 hexadecimal digits outputs the respective Unicode character.

There are also a bunch of escape sequences that correspond to emoticons, included for convenience.
To output these emoticons, you must put a backslash before any of the following:

- `^-^` outputs `😌`
- `:relaxed:` outputs `😌`
- `:P` outputs `😋`
- `:yum:` outputs `😋`
- `<3` outputs `❤️`
- `:heart_eyes:` outputs `❤️`
- `B)` outputs `😎`
- `:sunglasses:` outputs `😎`
- `:D` outputs `😀`
- `:grinning:` outputs `😀`
- `^o^` outputs `😄`
- `:smile:` outputs `😄`
- `XD` outputs `😆`
- `:laughing:` outputs `😆`
- `:lol:` outputs `😆`
- `=D` outputs `😃`
- `:smiley:` outputs `😃`
- `:sweat_smile:` outputs `😅`
- `DX` outputs `😱`
- `:tired_face:` outputs `😫`
- `;P` outputs `😜`
- `:stuck_out_tongue_winking_eye:` outputs `😜`
- `:-*` outputs `😘`
- `;-*` outputs `😘`
- `:kissing_heart:` outputs `😘`
- `:kissing:` outputs `😘`
- `:rofl:` outputs `🤣`
- `:)` outputs `🙂`
- `:slight_smile:` outputs `🙂`
- `:(` outputs `🙁`
- `:frown:` outputs `🙁`
- `:frowning:` outputs `🙁`

Expressions also give access to a full suite of operators and functions, listed on the next page.

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: misc_statements.md
[next]: lang_functions.md
