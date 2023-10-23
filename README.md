Paisley is a scripting language designed to allow for easy command-based behavior scripting.
The purpose of this language is NOT to be fast. Instead, Paisley is designed to be a simple, light-weight way to chain together more complex behavior (think NPC logic, train automation, etc.).
In particular, this language is meant to be as easy to learn as possible.

One advantage is that the script does not require any "pausing" logic that one would have to implement in order to get the same functionality in Lua; the Paisley runtime will automatically pause execution periodically to avoid Lua timeouts or performance drops, and will always wait on results from a command before continuing execution.

---
## Main program structures

As a general rule, white space and line endings *do not matter* in Paisley.
The only use of line endings is to separate commands, which can also be done with a semicolon `;` character.

A Paisley script may consist of a series of comments, statements, and/or commands.
- Comments begin with a `#` character and continue to the end of the line. There are no multi-line comments.
- There are 4 types of statements: conditionals (if/else/elif), loops (for/while), variable assignment, and subroutines.
- Any text that is not a keyword or otherwise part of a statement is considered a command. More on that later.

Before continuing, note that commands do not have to be hard-coded. You can put expressions in them, such as
```sh
let r = 500
print "r = {r}, d = {3.14 * r * r}"
```
See how in the above, expressions are contained inside curly braces, `{}`. More on that later.

## Conditionals:
"If" statements have the following structure:
```sh
if {expression is true-ish} then
	...
elif {expression is true-ish} then
	...
else
	...
end
```
Note that, unlike Lua's `elseif` keyword, the appropriate "else if" keyword in Paisley is `elif`.

## Loops:
While and For loops have a similar syntax to Lua:
```sh
while {expression is true-ish} do
	...
end

for variable in {expression} do
	...
end
```
Note that these are the only loop structures possible.
If you want syntax similar to Lua's integer for loops (`for i = 1, 10 do ... end`), you can use something like `for i in {1:10} do ... end`.

## Variable Assignment:
Variable assignment always starts with `let`, e.g.
```sh
let pi = 3.14
let circumference = {2 * pi * r}
```

## Subroutines:
Subroutines are a lot like functions, except they do not take any parameters, and do not return any value.
In Paisley, this does not matter much since all variables are global. Just keep in mind that you don't accidentally overwrite variables that are needed elsewhere.

An example subroutine usage might look like the following:
```sh
subroutine print_numbers:
	for i in {0:max_number} do
		if {i > 30} do
			print "whoa, too big!"
			return
		end
		print {i}
	end
end

let max_number = 10
gosub print_numbers

let max_number = 50
gosub print_numbers
```
Proper use of subroutines can let you easily reuse common code.

## Other statements:
- `break` or `break 1` or `break 2` etc, will exit as many while/for loops as are specified (defaults to 1 if not specified)
- `continue` or `continue 1` or `continue 2` etc, will skip an iteration of as many while/for loops as are specified (defaults to 1 if not specified)
- `delete` will delete the variables listed, e.g. `delete x y z`
- `stop` will immediately halt program execution.
- `return` returns from a subroutine back to the caller.

## Expressions:
Expressions can only exist inside curly braces, `{}`, and can be placed anywhere inside a command or statement operand. In addition, they can also be placed inside double-quoted strings (e.g. `"a = {1+2}"` gives `a = 3`) to perform easy string interpolation. Note that single-quoted strings **do not** interpolate expressions, so for example `'a = {1+2}'` would give exactly `a = {1+2}` without parsing any expression.

Expressions give access to a decent suite of operations and functions, listed below:

### Operators:
- addition, `+`
- subtraction or negative, `-`
- multiplication, `*`
- division, `/`
- *integer* division, `//` (divide then round down)
- remainder/modulo, `%`
- boolean operators, `and`, `or`, `xor`, `not`
- comparison, `>`, `>=`, `<`, `<=`
- comparison (equality), `=` or `==` (both are the same)
- comparison (not equal), `!=` or `~=` (both are the same)
- check for whether variables are set, `exists` (e.g. `x exists`)
- string or array length, `#` (e.g. `#variable`)
- array slicing, `:` (e.g. `0:5` gives `(0,1,2,3,4,5)`)
- array listing, `,` (e.g. `1,2,3` is an array with 3 elements, `(1,)` is array with 1 element, etc). can combine this with slicing, e.g. `1,3:5,9` gives `(1,3,4,5,9)`.
- array searching `in` (e.g. `3 in (1,2,4,5,6)` gives `false`)
- string concatenation: There is no string concatenation operator. Seriously, two values next to each other, without an operator between them, results in string concatenation.

### Allowed values:
- hexadecimal numbers, `0xFFFF`
- binary numbers, `0b1111`
- decimal numbers, `1.2345` or `12345` or `1_000_000`. Note that underscores are ignored by the compiler, you can use them for readability purposes.
- booleans, `true` or `false`
- nothing, `null`, equivalent to Lua's "nil"
- Strings with interpolation allowed, `"some text"`
- Strings with NO interpolation, `'some text'`
- variables, `var_name`, `x`, etc.
- The "global" variable, containing the names of all currently defined variables, `@`
- Sub-expressions, `{}`
- Inline command evaluation, `${}`

### Built-in functions:
- Random integer: `irandom(min_value, max_value) -> number`
- Random real number: `frandom(min_value, max_value) -> number`
- Difference between two strings: `worddiff(str1, str2) -> number`
- Euclidean distance (numbers or vectors of N dimension): `dist(point1, point2) -> number`
- Trig functions: `sin(x), cos(x), tan(x), asin(h), acos(h), atan(h), atan2(x, y) -> number`
- Square root: `sqrt(x) -> number`
- Average of N values: `mean(a,b,c,...) or mean(array) -> number`
- Sum of N values: `sum(a,b,c,...) or sum(array) -> number`
- Multiply N values: `mult(a,b,c,...) or mult(array) -> number`
- Exponent/Power: `pow(value, power) -> number`
- Minimum of N values: `min(a,b,c,...) or min(array) -> number`
- Maximum of N values: `max(a,b,c,...) or max(array) -> number`
- Keep value inside range: `clamp(min_value, max_value, variable) -> number`
- Linear interpolation of two numbers: `lerp(start, stop, ratio) -> number`
- Split string into array: `split(value, delimiter) -> array`
- Merge array into string: `join(values, delimiter) -> string`
- Get data type: `type(value) -> string`. Output will be one of "null", "boolean", "number", "string", or "array"
- Convert to boolean: `bool(value)`
- Convert to number: `num(value)`
- Convert to string: `str(value)`
- Convert to array: `array(value)`
- Round down: `floor(value) -> number`
- Round up: `ceil(value) -> number`
- Round to nearest integer: `round(value) -> number`
- Absolute value: `abs(value) -> number`
- Append value to an array: `append(array, value) -> array`
- Find index of value in an array: `index(array, value) -> number` (returns 0 if value was not found)

### Arrays in expressions
While you can absolutely create an array using the `array(...)` function, the simpler way to do it is to just include a comma in expressions.
For example, `(1,2,3)` is an array, as are `array(1,2,3)`, `(1,2,3,)` and `(1,)`. Note that expressions *are* allowed to have a trailing comma, which simply indicates that the expression is an array with a single element.

Note that an expression must contain a comma `,` or slice `:` operator to be considered an array, just parentheses is not enough.
So `(1,)` is an array and `(1:1)` is an equivalent array, but `(1)` is a number, not an array.

### Inline command evaluation
Since commands can return values to Paisley after execution, you can also use those values in further calculations. For example:
```
let emote_list = ${get emotes}
let last_emote = {emote_list[#emote_list]}
```

---

Lastly, to give an idea of the syntax, here is an example program that could check if the player is near an NPC and respond accordingly. Keep in mind that the actual commands available will vary based on the device.

```sh
	let start = ${time}

	#Wait until player approaches
	while {not ${player near}} do
		#Every 10 seconds, ask player to come here
		if {${time} - start > 10} then
			say "Hey, come over here!"
			let start = ${time}
		end
	end

	#Now that player is nearby, tell them a secret
	say "Did you know... I'm not wearing shoes."
```