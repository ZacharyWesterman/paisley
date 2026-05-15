# A Comprehensive Guide to Paisley

The following is a detailed breakdown of every language feature in Paisley. For some hands-on examples of programs, check out the `examples/` or `stdlib/` directories.

I'd also recommend checking out the [syntax specification](syntax.l) for an organized view of the syntax.

## Main program structures

As a general rule, white space and line endings *do not matter* in Paisley.
The only use of line endings is to separate commands, which can also be done with a semicolon `;` character.

A Paisley script may consist of a series of comments, statements, and commands.
- Single-line comments begin with a `#` character and continue to the end of the line.
- Multi-line comments begin with `#[[` and continue until `#]]` is reached, or the end of the file.
- There are 5 types of statements: conditionals (if/else/elif/match/try), loops (for/while), variable assignment, function definitions, and miscellaneous statements (return/break/etc).
- Any text that is not a keyword or otherwise part of a statement is considered a command. More on that later.

Before continuing, note that commands do not have to be hard-coded. You can put expressions in them, such as
```
let r = 500
print "r = {r}, d = {3.14 * r * r}"
```
See how in the above, expressions are contained inside curly braces, `{}`. More on that later.

---

### [Begin >](walkthrough/conditionals.md)
