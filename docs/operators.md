## Precedence

Operator precedence in Paisley follows the table below, from higher to lower priority:

`.`&emsp;`[]`<br>
`&`<br>
`^`<br>
`-`&emsp;`not`&emsp;`bitwise not`&emsp;(unary operators)<br>
`:`<br>
`*`&emsp;`/`&emsp;`//`&emsp;`%`<br>
`+`&emsp;`-`<br>
`>`&emsp;`<`&emsp;`>=`&emsp;`<=`&emsp;`=`&emsp;`!=`&emsp;`in`&emsp;`like`&emsp;`not in`&emsp;`not like`<br>
string concatenation `a b` (two expressions separated by a space)<br>
`exists`&emsp;`and`&emsp;`or`&emsp;`xor` and any `bitwise` versions of the latter 4.<br>
`a for b in c`&emsp;`a for b in c if d`<br>
`a else b`&emsp;&emsp;&emsp; `a if b else c`<br>
`=>`<br>
`,`<br>


## Operators

- addition, `+`
- subtraction or negative, `-`
- multiplication, `*`
- division, `/`
- *integer* division, `//` (divide then round down)
- remainder/modulo, `%`
- exponentiation, `^`, e.g. `a^3` raises `a` to the 3rd power.
- boolean operators, `and`, `or`, `xor`, `not`. Note that the `and` and `or` operators can short-circuit, i.e. given an expression `a and b`: if `a` is false, then the whole expression *can never be true*, so `b` is not even evaluated.
- bitwise operators, `bitwise and`, `bitwise or`, `bitwise xor`, `bitwise not`. Unlike the boolean operators, these do not short-circuit.
- comparison, `>`, `>=`, `<`, `<=`
- comparison (equality), `=` or `==` (the latter is deprecated)
- comparison (not equal), `!=` or `~=` (the latter is deprecated)
- check for whether variables are set, `exists` (e.g. `x exists`)
- string or array length, `&` (e.g. `&variable`)
- array slicing, `:`. Note that slices are inclusive of both their upper and lower bounds (e.g. `0:5` gives `(0,1,2,3,4,5)`)
- array listing, `,` (e.g. `1,2,3` is an array with 3 elements, `(1,)` is an array with 1 element, `(,)` has 0 elements, etc). You can combine this with slicing, e.g. `1,3:5,9` gives `(1,3,4,5,9)`.
- pattern matching, `like`, checks whether a string matches a given pattern (e.g. `"123" like "%d+"` gives `true`).
- array searching `in` (e.g. `3 in (1,2,4,5,6)` gives `false`)
- implicit string concatenation: There is no string concatenation operator. Seriously, two values next to each other, without an operator between them, results in string concatenation.
- ternary expression, `val1 if expression else val2`. Like Python's ternary syntax, this will result in `val1` if `expression` evaluates to true, otherwise it will result in `val2`.
- ternary operator, `val1 else val2`. Results in `val1` if val1 is truthy, otherwise results in `val2`.
- Indexing, `[]`. Like most languages, this lets you get an element from a string, array, or object (e.g. `"string"[2]` gives "t", `('a','b','c')[3]` gives "c", and `('a'=>'v1', 'b'=>'v2')['a']` gives "v1"), however Paisley also lets you select multiple items at once in a single index expression. E.g. `"abcde"[2,5,5]` gives "bee", `"abcde"[1:3]` gives "abc", `(6,7,8,9,0)[3,1,5]` gives `(8,6,0)`.

An extra note on slices: when slicing an array or a string, it's possible to replace the second number with a colon, to indicate that the slice should go from the start index all the way to the end of the string or array.
So for example, `"abcdef"[4::]` would result in `"def"`, `(5,4,3,2,1)[2::]` would result in `(4,3,2,1)`, etc.
