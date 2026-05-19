## Importing other files:
To allow organization and minimize bloat of individual scripts, Paisley does allow importing of other scripts with the `require` keyword. You can even import multiple files in the same statement.

```pai
#Import ./file1.pai or ./file1.paisley
require file1

#Import:
# ./file2.pai
# ./path/to/file3.pai
# ./"filename with spaces".pai
require file2 path.to.file3 "filename with spaces"

#Import ../file4.pai
require ..file4

#Import ../../file5.pai
require ...file5
```

See how it's possible to import files from N levels above, by prepending N+1 periods to the beginning of a path name.

Note that files can only be imported once, that is, any redundant imports are ignored.

## Other statements:
- `break` or `break 1` or `break 2` etc, will exit as many while/for loops as are specified (defaults to 1 if not specified)
- `continue` or `continue 1` or `continue 2` etc, will skip an iteration of as many while/for loops as are specified (defaults to 1 if not specified)
- `delete` will delete the variables listed, e.g. `delete x y z`
- `stop` will immediately halt program execution.
- `return` returns from a function back to the caller.
- `define` will parse the following expression(s) but will ignore them at run time. This is most useful for defining macros outside of where they're used.

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: scopes.md
[next]: expressions.md
