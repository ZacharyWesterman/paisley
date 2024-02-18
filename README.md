# Paisley
**PAISLey** (Plasma Automation / Instruction Scripting Language) is a scripting language designed to allow for easy command-based behavior scripting.
The purpose of this language is NOT to be fast. Instead, Paisley is designed to be a simple, light-weight way to chain together more complex behavior (think NPC logic, device automation, etc.).
This language is meant to make complex device logic very easy to implement, while also being as easy to learn as possible.

## FAQ
**Q:** *Why not use Lua instead?*<br>
**A:** The biggest advantage Paisley has over Lua nodes is that the script does not require any "pausing" logic that one would have to implement in order to get the same functionality in Lua; the Paisley runtime will automatically pause execution periodically to avoid Lua timeouts or performance drops, and will always wait on results from a command before continuing execution.

**Q:** *Why not use sketch nodes instead?*<br>
**A:** Paisley was designed as a language for scripting NPC behavior, and the thing about NPCs is that their behavior needs to be able to change in response to various events. First off, when using just sketch nodes, dynamically changing an NPC's programming is downright impossible. Second, connecting all the nodes necessary for every possible event is difficult and time consuming (for example NPC chatter, a sequence of movements, events that only happen ONCE, etc). TL;DR: NPC logic is difficult to implement using just sketch nodes. Trust me, I've done it.

**Q:** *How do I connect the Paisley engine to my device?*<br>
**A:** Get the Paisley Engine device from the Steam workshop (ID **3087775427**), and attach it to your device. Then in a different controller, set the inputs (Paisley code, a list of valid commands for this device, and optional file name), and make sure the "Run Command" output will eventually flow back into the "Command Return" input. Keep in mind this MUST have a slight delay (0.02s at least) or Plasma will detect it as an infinite loop!

**Q:** Why???<br>
**A:** haha

**Q:** Isn’t writing an entire compiler in Plasma a bit overkill?<br>
**A:** Your face is overkill. Compilers are fun, fight me.

---
## Main program structures

As a general rule, white space and line endings *do not matter* in Paisley.
The only use of line endings is to separate commands, which can also be done with a semicolon `;` character.

A Paisley script may consist of a series of comments, statements, and/or commands.
- Comments begin with a `#` character and continue to the end of the line. There are no multi-line comments.
- There are 5 types of statements: conditionals (if/else/elif), loops (for/while), variable assignment, subroutines, and miscellaneous statements (return/break/etc).
- Any text that is not a keyword or otherwise part of a statement is considered a command. More on that later.

Before continuing, note that commands do not have to be hard-coded. You can put expressions in them, such as
```
let r = 500
print "r = {r}, d = {3.14 * r * r}"
```
See how in the above, expressions are contained inside curly braces, `{}`. More on that later.

## Conditionals:
"If" statements have the following structure:
```
if {expression is true-ish} then
	...
elif {expression is true-ish} then
	...
else
	...
end
```

You can also leave out the “then” clause if all that’s needed is the “else” clause, e.g.:
```
if {expression is true-ish} else
	... do this if expression is false-ish ...
end
```

Note that, unlike Lua's `elseif` keyword, the appropriate "else if" keyword in Paisley is `elif`. Also keep in mind that if statements convert the expression to a boolean, and so use a few rules to test an expression’s trueness: false, null, zero, and empty strings are false-ish, everything else is true-ish. Arrays are always true-ish.

## Loops:
While and For loops have a similar syntax to Lua:
```
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
```
let pi = 3.14
let circumference = {2 * pi * r}
```
Note that the `let` keyword is required even when reassigning variables.
For example, consider the following:
```
let var = 13
var = 99
```
The second line will **not** set var's value to 13. Instead, that would attempt to run a command called "var" with the parameters `["=", "99"]`.

Of course, sometimes a variable will contain an array that you don't want to overwrite, instead you just want to update a *single element* or *append* to the array.
The following will result in var containing the array `(1, 2, 123, 4, 99)`. Note that giving negative values as the index will start counting from the end, so index of -1 will update the last element.
```
let var = 1 2 3 4 5
let var{3} = 123
let var{-1} = 99
```

Appending is just as simple. The following will result in var containing the array `(1, 2, 3, 4, 5, 6)`.
```
let var = 1 2 3 4 5
let var{} = 6
```

**REMEMBER:** All variables are global, so any “re-definition” of a variable just sets it to the new value.

## Subroutines:
Subroutines are a lot like functions, except they do not take any parameters, and do not return any value.
In Paisley, this does not matter much since all variables are global. Just keep in mind that you don't accidentally overwrite variables that are needed elsewhere.

An example subroutine usage might look like the following:
```
subroutine print_numbers
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

Note that it is also possible to jump to subroutines with an arbitrary label ID. See how in the following example, the program will randomly call one of 5 possible subroutines, and then print "Subroutine exists".
```
if gosub "{irandom(1,5)}" then
	print "Subroutine exists"
end

subroutine 1 end
subroutine 2 end
subroutine 3 end
subroutine 4 end
subroutine 5 end
```

## Lambdas:
Lambdas are another good way to reuse code, however unlike subroutines, these are specifically for reusing parts of expressions.
Lambdas are defined with the syntax `![expression]`, and are referred to with that same `!` identifier, just without the brackets. Note that the `!` can be any number of exclamation marks, optionally followed by an alphanumeric identifier. So for example, `!!`, `!2`, and `!!lambda_1` are all valid lambda identifiers, all referring to different lambdas. Note that unlike lambdas in other languages, lambdas in Paisley are not true functions; they don't take any parameters. However, they do have access to the same global scope as the rest of the program.

Below is an example of lambda usage. Both the top and bottom commands will print 5 random numbers in the range 0-100.
```
print {![irandom(0, 100)], !, !, !, !}

#do the same thing, but using the define keyword
define {!rnd[irandom(0, 100)]}
print {!rnd, !rnd, !rnd, !rnd, !rnd}
```
Note that either of the above commands are equivalent to the following:
```
print {irandom(0, 100), irandom(0, 100), irandom(0, 100), irandom(0, 100), irandom(0, 100)}
```

Unlike variables, lambdas are restricted to their scope. Thus, for example, if you define a lambda in a subroutine, you cannot use it outside the subroutine, unless that outside scope also has a lambda definition with the same identifier.

## Other statements:
- `break` or `break 1` or `break 2` etc, will exit as many while/for loops as are specified (defaults to 1 if not specified)
- `continue` or `continue 1` or `continue 2` etc, will skip an iteration of as many while/for loops as are specified (defaults to 1 if not specified)
- `delete` will delete the variables listed, e.g. `delete x y z`
- `stop` will immediately halt program execution.
- `return` returns from a subroutine back to the caller.
- `define` will parse the following expression(s) but will ignore them at run time. This is most useful for defining lambdas outside of where they're used.

## Expressions:
First and foremost, expressions will only be evaluated inside curly braces, `{}`. If you place an expression outside of braces, it will be treated as plain text. For example `print {1+2}` will print "3" but `print 1+2` will print the actual string "1+2".

Expressions can be placed anywhere inside a command or statement operand. In addition, they can also be placed inside double-quoted strings (e.g. `"a = {1+2}"` gives `a = 3`) to perform easy string interpolation. Note that single-quoted strings **do not** interpolate expressions, so for example `'a = {1+2}'` would give exactly `a = {1+2}` without parsing any expression.

If you would like to avoid interpolation in double-quoted strings, simply escape the opening curly brace with a backslash, e.g.
```
print "the expression \{1+2} evaluates to {1+2}"
print "you can also put \"quotes\" and line breaks (\n) inside strings!"
```
There are a few special escape codes:
- `\n` outputs a line ending.
- `\t` outputs a tab.
- `\s` outputs a non-breaking space.
- Any others just output the character after the backslash, e.g. `\"` &rarr; "

Expressions also give access to a full suite of operators and functions, listed below:

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
- array slicing, `:`. Note that slices are inclusive of both their upper and lower bounds (e.g. `0:5` gives `(0,1,2,3,4,5)`)
- array listing, `,` (e.g. `1,2,3` is an array with 3 elements, `(1,)` is an array with 1 element, `(,)` has 0 elements, etc). can combine this with slicing, e.g. `1,3:5,9` gives `(1,3,4,5,9)`.
- pattern matching, `like`, checks whether a string matches a given pattern (e.g. `"123" like "%d+"` gives `true`).
- array searching `in` (e.g. `3 in (1,2,4,5,6)` gives `false`)
- string concatenation: There is no string concatenation operator. Seriously, two values next to each other, without an operator between them, results in string concatenation.
- ternary operator, `val1 if expression else val2`. Like Python’s ternary syntax, this will result in `val1` if `expression` evaluates to true, otherwise it will result in `val2`.

### Allowed values:
- hexadecimal numbers, `0xFFFF`
- binary numbers, `0b1111`
- decimal numbers, `1.2345` or `12345` or `1_000_000`. Note that underscores are ignored by the compiler, you can use them for readability purposes.
- booleans, `true` or `false`
- `null`, equivalent to Lua's "nil"
- Strings with interpolation allowed, `"some text"`
- Strings with NO interpolation, `'some text'`
- variables, `var_name`, `x`, etc.
- The "global" variable, containing the names of all currently defined variables, `@`
- The "command list" variable, containing the names of all allowed commands, `$`
- Inline command evaluation, `${}`

### Built-in functions:
- Random integer: `irandom(min_value, max_value) -> number`
- Random real number: `frandom(min_value, max_value) -> number`
- Select a random element from a list: `select_random(array) -> any`
- Difference between two strings: `worddiff(str1, str2) -> number` (levenschtein distance)
- Euclidean distance (numbers or vectors of N dimension): `dist(point1, point2) -> number`
- Trig functions: `sin(x), cos(x), tan(x), asin(x), acos(x), atan(x), atan2(x, y) -> number`
- Square root: `sqrt(x) -> number`
- Split a number into bytes: `bytes(number, count) -> array`
- Convert a list of bytes into a number: `frombytes(array) -> number`
- Sum of N values: `sum(a,b,c,...) or sum(array) -> number`
- Multiply N values: `mult(a,b,c,...) or mult(array) -> number`
- Exponent/Power: `pow(value, power) -> number`
- Minimum of N values: `min(a,b,c,...) or min(array) -> number`
- Maximum of N values: `max(a,b,c,...) or max(array) -> number`
- Keep value inside range: `clamp(number, min_value, max_value) -> number`
- Linear interpolation of two numbers: `lerp(ratio, start, stop) -> number`
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
- Convert string to lowercase: `lower(text) -> string`
- Convert string to uppercase: `upper(text) -> string`
- Capitalize the first letter of every word: `camel(text) -> string`
- Replace all occurrences of a sub-string: `replace(text, search, replace) -> string`
- Serialize data to a JSON string: `json_encode(data) -> string`
- Deserialize data from a JSON string: `json_decode(text) -> any`
- Convert a string to base64: `b64_encode(text) -> string`
- Convert base64 text to a string: `b64_decode(text) -> string`
- Left-pad a string with a given character: `lpad(string, character, to_width) -> string`
- Right-pad a string with a given character: `rpad(string, character, to_width) -> string`
- Convert a number to a hexadecimal string: `hex(value) -> string`
- Remove all characters that do not match the given pattern: `filter(text, pattern) -> string`
- Get the first match of a pattern in the given text: `match(text, pattern) -> string`. If no match is found, a null string is returned.
- Convert a “seconds since midnight” timestamp into (hour, min, sec, milli): `clocktime(value) -> array`
- Reduce an array to a single element: `reduce(array, operator) -> any`, e.g. `reduce(1:9, +)` sums the numbers from 1 to 9, resulting in 45
- Reverse an array or a string: `reverse(array) -> array` or `reverse(string) -> string`
- Sort an array in ascending order: `sort(array) -> array`
- Join two arrays together: `merge(array, array) -> array`
- Replace an element in an array: `update(array, index, value) -> array`
- Insert an element in an array: `insert(array, index, value) -> array`
- Delete an element from an array: `delete(array, index) -> array`

Note that functions can be called in one of two ways:
1. The usual syntax, e.g. `split(var, delim)`
2. Using dot-notation, e.g. `var.split(delim)`

Both are exactly equivalent, the latter syntax is included simply for convenience.

### Arrays in expressions
While you can absolutely create an array using the `array(...)` function, the simpler way to do it is to just include a comma in expressions.
For example, `(1,2,3)` is an array, as are `array(1,2,3)`, `(1,2,3,)`, `(1,)` and `(,)`. Note that expressions *are* allowed to have a trailing comma, which simply indicates that the expression is an array with a single element. Likewise, a single comma by itself indicates an empty array.

Note that an expression must contain a comma `,` or slice `:` operator to be considered an array, just parentheses is not enough.
So `(1,)` is an array and `(1:1)` is an equivalent array, but `(1)` is a number, not an array.

### List comprehension
Often you need to take an array and mutate every element in some way. While you could very well use a for loop for this, this operation comes up often enough that there is a convenient shorthand for it. See how in the following script, we're taking the array `x` and multiplying every element by `2`, then assigning the result to `y`.
```
let x = {1,2,3}
let y = {array()}
for i in {x} do
	let y = {append(y, x * 2)}
end
```
The above could be written much more succinctly as the following:
```
let x = {1,2,3}
let y = {i * 2 for i in x}
```

Those of you familiar with Python will realize where the syntax comes from, and like in Python, you can filter out array elements based on a condition. See how in the following script, `x` is all numbers from 1 to 100, and we're selecting only those numbers divisible by `5`, and storing the result in `y`.
```
let x = {1:100}
let y = {array()}
for i in {x} do
	if {i % 5 = 0} then
		let y = {append(y, x)}
	end
end
```
The above could instead be written as the following:
```
let x = {1:100}
let y = {i for i in x if i % 5 = 0}
```

### Inline Command Evaluation
Since commands can return values to Paisley after execution, you can also use those values in further calculations. For example:
```
#Get an integer value representing in-game time, and convert it to a human-readable format
let t = {floor(${time})}
let hour = {t // 3600}
let minute = {(t // 60) % 60}
let second = {t % 60}
print {hour ":" minute ":" second}
```
Of course, there is also a simpler version that does the same thing:
```
print {${time}.clocktime()[1:3].join(":")}
```

### Built-in commands
For ease of use and consistency, there are 6 built-in commands that will always be the same regardless of device.
- `time`: Returns a number representing the in-game time. Arguments are ignored.
- `systime`: Returns a number representing the system time (seconds since midnight). Arguments are ignored.
- `sysdate`: Returns a numeric array containing the system day, month, and year (in that order). Arguments are ignored.
- `print`: Send all arguments to the "print" output, as well as to the internal log.
- `error`: Send all arguments (plus line number and file, if applicable) to the "error" output, as well as to the internal warning log.
- `sleep`: Pause script execution for the given amount of seconds. If the first argument is not a positive number, delay defaults to minimum value (0.02s).

Note that all commands take a little bit of time to run (at least 0.02s), whether they're built-in or not. This is to prevent "infinite loop" errors or performance drops.

---

Lastly, to give an idea of the syntax, here is an example program that will create a clock that stays in sync with the client system.

```
#Repeat forever. "while 1 do" would also work.
while {true} do
	#Format date as YYYY-MM-DD
	let date = {${sysdate}.reverse().join('-')}

	#Format time as HH:MM:SS
	#Note the lpad() use makes sure that hours/minutes/seconds are always 2 digits
	let time = {(i.lpad('0', 2) for i in ${systime}.clocktime()[1:3]).join(':')}
	print {date ' @ ' time}

	#Only update once per second
	sleep 1
end
```
