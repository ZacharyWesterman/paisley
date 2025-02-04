# Paisley
<table>
<tr>
<td>
<img src="images/paisley-logo-small.png" align="left">

**Paisley** is a scripting language designed to allow for easy command-based behavior scripting. It's designed to be a simple, light-weight way to chain together more complex behavior from existing commands, while also having a "batteries included" mindset when it comes to manipulating the output of those commands.
As such, there is a whole suite of operations and functions for quick and easy data manipulation. 

</td>
</tr>
</table>

---

## FAQ

**Q:** *Where does the name "Paisley" come from?*<br>
**A:** Originally it was an acronym "PAISLey" with an embarassing leftover "ey" that didn't stand for anything; but nowadays its name is just "Paisley", no acronym. If you want to assign a meaning to the name, you could say that paisleys are a simple pattern where you repeat pretty little curlies over and over all the way down. Likewise, Paisley is a simple language whose expression syntax uses curly braces all the way down. That's a potential answer at least. The real answer is that I like how paisleys look.

**Q:** *What niche does Paisley fill?*<br>
**A:** Paisley would fill a similar niche to Bash scripts, where you're chaining together other scripts/programs to make more complex logic. Similar to bash, commands can be run just by typing the command name and parameters separated by spaces. Basically, it's somewhere between Bash and Python; fitting the shell-language niche while also having batteries included.

**Q:** *What does Paisley do different?*<br>
**A:** Simple and consistent syntax for one. As much as I love Bash, the syntax is quite frankly a *mess*. There are so many gotchas and oddities. E.g. expressions use `$((...))` but don't support floats, the language itself doesn't have actual types, not to mention constantly having to think about globbing and whether stuff is escaped or not. Paisley is very simple in that, if it's inside `{...}`, then it's an expression. It also supports arbitrarily nested data (3d arrays anyone?), which Bash does not.

**Q:** *Why is this written in Lua?*<br>
**A:** Originally this was written for use in a game called Plasma; this game would let you create node-based programs and Lua scripts to control machines, though the version of Lua was quite limited in features. This language was written to get around the tedium and limitations of certain aspects of the game engine, but snowballed into a bit of a passion project as well as a proof of concept that, yes, you can write a compiler in Lua without any extra dependencies. Many, many updates later, we have Paisley as it stands now. There is still a [Plasma Version FAQ](docs/plasma_version.md) if you're interested in that.

---

## Installing Paisley

Dependencies:
- Lua
- Python (for installing)

If you don't want to install any lua dependencies, you can just run `./paisley` and it should work fine. No Python needed in this case.

On Linux systems, just run `./install.sh` and it will install Lua rocks for all extra features, then compile Paisley into a single file and install on your system.
On Windows, there is no build, just run Paisley locally.

To uninstall, just run `./uninstall.sh`.

Once installed, you can check out the examples, or run `paisley --help` for usage info.

**NOTE:** If you for whatever reason *can't* install Lua or Python on your system, there is also a standalone build available in the latest tag.

---
---

![logo](images/paisley-logo.png)

# Syntax

The following is a detailed breakdown of every language feature in Paisley. For some hands-on examples of programs, check out the `examples/` or `stdlib/` directories.

## Main program structures

As a general rule, white space and line endings *do not matter* in Paisley.
The only use of line endings is to separate commands, which can also be done with a semicolon `;` character.

A Paisley script may consist of a series of comments, statements, and commands.
- Comments begin with a `#` character and continue to the end of the line. There are no multi-line comments.
- There are 5 types of statements: conditionals (if/else/elif/match/try), loops (for/while), variable assignment, subroutines, and miscellaneous statements (return/break/etc).
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
if {expression is truey} then
	...
elif {expression is truey} then
	...
else
	...
end
```

You can also leave out the "then" clause if all that's needed is the "else" clause, e.g.:
```
if {expression is truey} else
	... do this if expression is falsey ...
end
```

Note that, unlike Lua's `elseif` keyword, the appropriate "else if" keyword in Paisley is `elif`. Also keep in mind that if statements convert the expression to a boolean, and so use a few rules to test an expression's trueness: false, null, zero, empty strings, empty arrays and empty objects are all falsey, everything else is truey.

There is also the `match` structure, which is similar to c-like languages' `switch/case` structure (or Rust's `match`). This structure is included to allow for more readable logic with less repeated code.
```
match {expression} do
	if {case 1} then ... end
	if {case 2} then ... end
	...
else
	... default action if no cases match ...
end
```
For example:
```
match {random_int(1,5)} do
	if 1 then print one end
	if 2 then print two end
	if {> 4} then print 4 or 5 end
	if {like '%d+'} then error "it's a string?!" end
else
	print "some other number"
end
```
Note how, inside match statements, the top-level boolean operators (`=`, `!=`, `>`, `<`, `>=`, `<=`, `like`) don't have a left operand.
Instead, the left operand is implied to be the value of the match expression.
If the operator is left out, then `=` is implied. e.g. `{3}` is the same as `{=3}`.

Of course, like `if` statements, the `else` branch is optional and can be excluded.

## Loops:
While and For loops have a similar syntax to Lua:
```
while {expression is truey} do
	...
end

for value in {expression} do
	...
end

for key value in {pairs(object or array)} do
	...
end
```
These are the only loop structures possible.
Note that the middle loop type will iterate over all *values* in an array, and all *keys* in an object!

If you want syntax similar to Lua's integer for loops (`for i = 1, 10 do ... end`), you can use something like `for i in {1:10} do ... end`.
If you want an infinite loop, just use something like `while 1 do ... end` or `while {true} do ... end`.

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
The second line will **NOT** set var's value to 13. Instead, that would attempt to run a command called "var" with the parameters `["=", "99"]`.

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

You can also assign multiple variables at the same time.
```
let a b c = 1 2 3

#Alternatively, you can assign variables from values in an array
let list = {1:9}
let a b c = {list}
```

To simply define a variable as null, you can just leave off the expression. The following all initialize variables as null.
```
let var
let a b c
let foo = {null}
```

**REMEMBER:** All variables are global, so any "re-definition" of a variable just sets it to the new value.

### Variable Initialization:

There is a special keyword for setting a variable's value if it hasn't been assigned already.
```
initial variable = {value}
```
Unlike the `let` keyword, `initial` can only define one variable, and it cannot insert or update sub-elements in arrays. The use of `initial` is instead a concise way to set a default value for un-initialized variables. Logically, it is identical to the following:
```
if {not (variable exists)} then
	let variable = {value}
end
```

## Subroutines:
Proper use of subroutines can let you easily reuse common code.

Subroutines are basically user-defined functions that are called as if they were commands. Like commands, they can take parameters and optionally return a value, but they don't have to.
Unlike commands, they can modify global variables, which may or may not be desired. Just keep it in mind when writing subroutines.

An example subroutine usage might look like the following:
```
subroutine print_numbers
	for i in {0 : @[1]} do
		if {i > 30} then
			print "whoa, too big!"
			return
		end
		print {i}
	end
end

gosub print_numbers 10
gosub print_numbers 50

subroutine power
    return {@[1] ^ @[2]}
end

print ${gosub power 2 10}
```
See how in the above, the `@` variable stores any parameters passed to a subroutine as an array, so the first parameter is `@[1]`, the second is `@[2]` and so on. For constant indexes, the square brackets are optional, e.g. `@1` and `@2` will also work, but **not** `@ 2`.
Also see that subroutines return values the same way that commands do, using the inline command evaluation syntax, `${...}`.

Note that it is also possible to jump to subroutines with an arbitrary label ID. Unlike a regular gosub, a dynamic gosub could fail at runtime, and so requires a conditional check `if gosub {expression} then ... else ... end` to make sure the label is valid.
See how in the following example, the program will randomly call one of 5 possible subroutines, and then print "Subroutine exists".
```
if gosub "{random_int(1,5)}" then
	print "Subroutine exists"
end

subroutine 1 end
subroutine 2 end
subroutine 3 end
subroutine 4 end
subroutine 5 end
```

### Subroutines in Expressions:
Inside of expressions, subroutines can be called in one of two ways:
1. Using the inline command evaluation syntax `${...}`, in the same way as commands are used. E.g. `${gosub my_subroutine {arg1} arg2 "arg3" etc..}`
2. Using the special function evaluation syntax `\my_subroutine(arg1,arg2,etc...)`.

These both do exactly the same thing: the latter is just syntax sugar for the former, and is supplied for convenience.

### Subroutine Memoization:
Some subroutines may take a very long time to compute values, when we only really need them to be computed once for any given input.
For these kinds of subroutines, the `cache` keyword can be used to memoize the subroutine and only compute the results once.
See the following recursive fibonacci example:
```
cache subroutine fib
	if {@1 < 2} then return {@1} end
	return {
		${gosub fib {@1 - 1}} +
		${gosub fib {@1 - 2}}
	}
end
```
Subsequent calls to `fib` will be *very* fast, because each fibonacci number only has to be computed once.

If it turns out that you need to invalidate a specific subroutine's cache, you can manually do so:
```
break cache fib
```
If the subroutine is not memoized, this of course does nothing.

In short, memoization can be a good way to get a significant performance boost, basically for free (there *is* a slight runtime overhead, but it's negligible). Do keep in mind that any side effects (e.g. running commands, modifying variables, etc) of the called subroutine will not trigger if the result is already cached, so do not use this feature if you *want* your subroutine to always cause side effects.

### Subroutine Aliases:

Some subroutines may have very long names that are unwieldy to type. In such cases you can create an alias with the `using` keyword:
```
subroutine very_long_name_thats_annoying_to_type end
using very_long_name_thats_annoying_to_type as short_name
gosub short_name

#If your subroutine name has at least one period in it,
#then you don't have to manually write the alias name.
#It will be deduced from the text after the last period.
subroutine example.sub end
using example.sub
gosub sub
```
Do note that aliases are restricted to their scope, for example:
```
subroutine example.sub end
if {x} then
	using example.sub as mysub
	gosub mysub #This is valid.
end
gosub mysub #This is an error; "mysub" alias is not defined in this scope.
```
You can also alias subroutines according to a wildcard, if you end the subroutine name with an asterisk.
```
subroutine sub1 end
subroutine sub2 end
using sub* as * #Can now do `gosub 1` and `gosub 2`
using sub* as s* #Can now do `gosub s1` and `gosub s2`
using sub* as *s #Can now do `gosub 1s` and `gosub 2s`
using nonexistent.sub.* #Nothing happens unless at least 1 subroutine matches the pattern.
```
Note that aliases do NOT work with dynamic gosubs; those require the full subroutine name, to avoid any ambiguity at runtime.

## Macros:
Macros are another good way to reuse code, however unlike subroutines, these are specifically for reusing parts of expressions.
Macros are defined with the syntax `![expression]`, and are referred to with that same `!` identifier, just without the brackets. Note that the `!` can be any number of exclamation marks, optionally followed by an alphanumeric identifier. So for example, `!!`, `!2`, and `!!macro_1` are all valid macro identifiers, all referring to different macros. Note that macros are not functions; they don't take any parameters, instead they behave exactly as if you had written the contained expression instead of the macro.

Below is an example of macro usage. Both the top and bottom commands will print 5 random numbers in the range 0-100.
```
print {![random_int(0, 100)], !, !, !, !}

#do the same thing, but using the define keyword
define {!rnd[random_int(0, 100)]}
print {!rnd, !rnd, !rnd, !rnd, !rnd}
```
Note that either of the above commands are equivalent to the following:
```
print {random_int(0, 100), random_int(0, 100), random_int(0, 100), random_int(0, 100), random_int(0, 100)}
```

Unlike variables, macros are restricted to their scope. Thus, for example, if you define a macro in a subroutine, you cannot use it outside the subroutine, unless that outside scope also has a macro definition with the same identifier.

## Exceptions:
Sometimes, parts of a program **will** fail, and the failure point is not always easy to predict. Many languages use exceptions to gracefully handle errors, and Paisley does so as well. To raise an exception, use the `error` command along with any message. And then to handle an exception, you can use a `try/catch` block, where the `catch` can have an optional variable to set.

```
subroutine this_errors
	error "your error message"
end

try
	gosub this_errors
catch e
	print {json_encode(e)}
end
```
The output variable (in this case `e`) will always be an object that looks like the following:
```
{
	"message": "your error message",
	"line": 6,
	"stack": [2] 
}
```
Where `line` is the line where the exception was caught, and `stack` is the line numbers for the subroutine call stack.

## Importing other files:
To allow organization and minimize bloat of individual scripts, Paisley does allow importing of other scripts with the `require` keyword. You can even import multiple files in the same statement.

```
#Import ./file1.pai or ./file1.paisley
require file1

#Import:
# ./file2.pai
# ./path/to/file3.pai
# ./"filename with spaces".pai
require file2 path.to.file3 "filename with spaces"
```

Note that these imports follow a strict top-down file structure (you can never go up a directory) and importing the same file more than once is an error.

## Other statements:
- `break` or `break 1` or `break 2` etc, will exit as many while/for loops as are specified (defaults to 1 if not specified)
- `continue` or `continue 1` or `continue 2` etc, will skip an iteration of as many while/for loops as are specified (defaults to 1 if not specified)
- `delete` will delete the variables listed, e.g. `delete x y z`
- `stop` will immediately halt program execution.
- `return` returns from a subroutine back to the caller.
- `define` will parse the following expression(s) but will ignore them at run time. This is most useful for defining macros outside of where they're used.

## Expressions:
First and foremost, expressions will only be evaluated inside curly braces, `{}`. If you place an expression outside of braces, it will be treated as plain text. For example `print {1+2}` will print "3" but `print 1+2` will print the actual string "1+2".

Expressions can be placed anywhere inside a command or statement operand. In addition, they can also be placed inside double-quoted strings (e.g. `"a = {1+2}"` gives `a = 3`) to perform easy string interpolation. Note that single-quoted strings **do not** interpolate expressions, so for example `'a = {1+2}'` would give exactly `a = {1+2}` without parsing any expression.

If you would like to avoid interpolation in double-quoted strings, simply escape the opening curly brace with a backslash, e.g.
```
print "the expression \{1+2} evaluates to {1+2}"
print "you can also put \"quotes\" and line breaks (\n) inside strings!"
```
There are a few special escape sequences:
- `\n` outputs a line ending.
- `\t` outputs a tab.
- `\r` outputs a carriage return.
- `\ ` (backslash + space) outputs a non-breaking space.
- `\"` outputs a double quote.
- `\'` outputs a single quote.
- `\{` outputs a left curly brace.
- `\}` outputs a right curly brace.
- `\x` followed by any 2 hexadecimal digits outputs the respective byte.

There are also a bunch of escape sequences that correspond to emoticons, included for convenience:
- `\^-^` outputs `<sprite=0>`
- `\:relaxed:` outputs `<sprite=0>`
- `\:P` outputs `<sprite=1>`
- `\:yum:` outputs `<sprite=1>`
- `\<3` outputs `<sprite=2>`
- `\:heart_eyes:` outputs `<sprite=2>`
- `\B)` outputs `<sprite=3>`
- `\:sunglasses:` outputs `<sprite=3>`
- `\:D` outputs `<sprite=4>`
- `\:grinning:` outputs `<sprite=4>`
- `\^o^` outputs `<sprite=5>`
- `\:smile:` outputs `<sprite=5>`
- `\XD` outputs `<sprite=6>`
- `\:laughing:` outputs `<sprite=6>`
- `\:lol:` outputs `<sprite=6>`
- `\=D` outputs `<sprite=7>`
- `\:smiley:` outputs `<sprite=7>`
- `\:sweat_smile:` outputs `<sprite=9>`
- `\DX` outputs `<sprite=10>`
- `\:tired_face:` outputs `<sprite=10>`
- `\;P` outputs `<sprite=11>`
- `\:stuck_out_tongue_winking_eye:` outputs `<sprite=11>`
- `\:-*` outputs `<sprite=12>`
- `\;-*` outputs `<sprite=12>`
- `\:kissing_heart:` outputs `<sprite=12>`
- `\:kissing:` outputs `<sprite=12>`
- `\:rofl:` outputs `<sprite=13>`
- `\:)` outputs `<sprite=14>`
- `\:slight_smile:` outputs `<sprite=14>`
- `\:(` outputs `<sprite=15>`
- `\:frown:` outputs `<sprite=15>`
- `\:frowning:` outputs `<sprite=15>`

Expressions also give access to a full suite of operators and functions, listed below:

### Operators:
- addition, `+`
- subtraction or negative, `-`
- multiplication, `*`
- division, `/`
- *integer* division, `//` (divide then round down)
- remainder/modulo, `%`
- exponentiation, `^`, e.g. `a^3` raises `a` to the 3rd power.
- boolean operators, `and`, `or`, `xor`, `not`. Note that the `and` and `or` operators can short-cut, i.e. given an expression `a and b`: if `a` is false, then the whole expression *can never be true*, so `b` is not even evaluated.
- comparison, `>`, `>=`, `<`, `<=`
- comparison (equality), `=` or `==` (both are the same)
- comparison (not equal), `!=` or `~=` (both are the same)
- check for whether variables are set, `exists` (e.g. `x exists`)
- string or array length, `&` (e.g. `&variable`)
- array slicing, `:`. Note that slices are inclusive of both their upper and lower bounds (e.g. `0:5` gives `(0,1,2,3,4,5)`)
- array listing, `,` (e.g. `1,2,3` is an array with 3 elements, `(1,)` is an array with 1 element, `(,)` has 0 elements, etc). You can combine this with slicing, e.g. `1,3:5,9` gives `(1,3,4,5,9)`.
- pattern matching, `like`, checks whether a string matches a given pattern (e.g. `"123" like "%d+"` gives `true`).
- array searching `in` (e.g. `3 in (1,2,4,5,6)` gives `false`)
- string concatenation: There is no string concatenation operator. Seriously, two values next to each other, without an operator between them, results in string concatenation.
- ternary operator, `val1 if expression else val2`. Like Python's ternary syntax, this will result in `val1` if `expression` evaluates to true, otherwise it will result in `val2`.
- Indexing, `[]`. Like most languages, this lets you get an element from a string, array, or object (e.g. `"string"[2]` gives "t", `('a','b','c')[3]` gives "c", and `('a'=>'v1', 'b'=>'v2')['a']` gives "v1"), however Paisley also lets you select multiple items at once in a single index expression. E.g. `"abcde"[2,5,5]` gives "bee", `"abcde"[1:3]` gives "abc", `(6,7,8,9,0)[3,1,5]` gives `(8,6,0)`.

An extra note on slices: when slicing an array or a string, it's possible to replace the second number with a colon, to indicate that the slice should go from the start index all the way to the end of the string or array.
So for example, `"abcdef"[4::]` would result in `"def"`, `(5,4,3,2,1)[2::]` would result in `(4,3,2,1)`, etc.

### Allowed values:
- Hexadecimal numbers, `0xFFFF`
- Binary numbers, `0b1111`
- Decimal numbers, `1.2345` or `12345` or `1_000_000`. Note that underscores are ignored by the compiler, you can use them for readability purposes.
- Booleans, `true` or `false`
- `null`, equivalent to Lua's "nil"
- Strings with interpolation allowed, `"some text"`
- Strings with NO interpolation, `'some text'`
- Variables, `var_name`, `x`, etc.
- The "parameter list" variable, an array containing any values passed to the current subroutine, `@`
- The "command list" variable, an array containing the names of all allowed commands, `$`
- The "variables" variable, an object that contains variable names and values, `_VARS`
- Inline command evaluation, `${}`
- Arrays, e.g. `(1,2,3,4,5)`
- Objects, e.g. `("a" => 1, "b" => 2)`

### Built-in functions:
- Random integer: `random_int(min_value, max_value) -> number`
- Random real number: `random_float(min_value, max_value) -> number`
- Select a random element from a list: `random_element(array) -> any`
- Select (non-repeating) random elements from a list: `random_elements(array, count) -> array`
- Shuffle an array's elements into a random order: `shuffle(array) -> array`
- Difference between two strings: `word_diff(str1, str2) -> number` ([Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance))
- Euclidean distance (numbers or vectors of N dimension): `dist(point1, point2) -> number`
- Trig functions: `sin(x), cos(x), tan(x), asin(x), acos(x), atan(x), atan2(x, y), sinh(x), cosh(x), tanh(x) -> number`
- Square root: `sqrt(x) -> number`
- Get the sign of a number: `sign(number) -> number`. Returns -1 if a number is negative, 0 if zero, or 1 if positive.
- Split a number into bytes: `bytes(number, count) -> array`
- Convert a list of bytes into a number: `frombytes(array) -> number`
- Sum of N values: `sum(a,b,c,...) or sum(array) -> number`
- Multiply N values: `mult(a,b,c,...) or mult(array) -> number`
- Minimum of N values: `min(a,b,c,...) or min(array) -> number`
- Maximum of N values: `max(a,b,c,...) or max(array) -> number`
- Keep value inside range: `clamp(number, min_value, max_value) -> number`
- Smoothly transition from 0 to 1 in a given range: `smoothstep(number, min_value, max_value) -> number`
- Linear interpolation of two numbers: `lerp(ratio, start, stop) -> number`
- Split string into array: `split(value, delimiter) -> array`. Note that unlike in Lua, the delimiter is just a string, not a pattern.
- Merge array into string: `join(values, delimiter) -> string`
- Count the number of occurrences of a value in an array or string: `count(array/string, value) -> number`
- Find the index of the nth occurrence of a value in an array or string: `find(array/string, value, n) -> number`. Returns 0 if not found.
- Find the index of the first occurrence of a value in an array or string: `index(array/string, value) -> number`. Returns 0 if not found.
- Get data type: `type(value) -> string`. Output will be one of "null", "boolean", "number", "string", "array", or "object"
- Convert to boolean: `bool(value) -> boolean`
- Convert to number: `num(value) -> number`
- Convert to integer: `int(value) -> number`. This is functionally equivalent to `floor(num(value))`
- Convert to string: `str(value) -> string`
- Convert a number of any base to a string: `numeric_string(value, base, pad_width) -> string`
- Round down: `floor(value) -> number`
- Round up: `ceil(value) -> number`
- Round to nearest integer: `round(value) -> number`
- Absolute value: `abs(value) -> number`
- Convert a character to its ASCII value: `ascii(string) -> number`. Only the first character is considered, all others are ignored.
- Convert an ASCII number to a character: `char(number) -> string`. If outside of the range 0-255, an empty string is returned. Non-integers are rounded down.
- Append value to an array: `append(array, value) -> array`
- Convert string to lowercase: `lower(text) -> string`
- Convert string to uppercase: `upper(text) -> string`
- Capitalize the first letter of every word: `camel(text) -> string`
- Replace all occurrences of a substring: `replace(text, search, replace) -> string`
- Check if a string begins with a given substring: `beginswith(search, substring) -> boolean`
- Check if a string ends with a given substring: `endswith(search, substring) -> boolean`
- Serialize data to a JSON string: `json_encode(data) -> string`
- Deserialize data from a JSON string: `json_decode(text) -> any`
- Check if a JSON string is formatted correctly: `json_valid(text) -> boolean`
- Convert a string to base64: `b64_encode(text) -> string`
- Convert base64 text to a string: `b64_decode(text) -> string`
- Left-pad a string with a given character: `lpad(string, character, to_width) -> string`
- Right-pad a string with a given character: `rpad(string, character, to_width) -> string`
- Convert a number to a hexadecimal string: `hex(value) -> string`
- Remove all characters that do not match the given pattern: `filter(text, pattern) -> string`
- Get all substrings that match the given pattern: `matches(text, pattern) -> array[string]`
- Convert a "seconds since midnight" timestamp into (hour, min, sec, milli): `clocktime(value) -> array`
- Convert a timestamp or clocktime into an ISO time string: `time(timestamp) -> string`
- Convert a date array into an ISO date string: `date(date_array) -> string`
- Reduce an array to a single element: `reduce(array, operator) -> any`, e.g. `reduce(1:9, +)` sums the numbers from 1 to 9, resulting in 45. *This works for any boolean or arithmetic operator!*
- Reverse an array or a string: `reverse(array) -> array` or `reverse(string) -> string`
- Sort an array in ascending order: `sort(array) -> array`
- Join two arrays together: `merge(array, array) -> array`
- Replace an element in an array: `update(array, index, value) -> array`
- Insert an element in an array: `insert(array, index, value) -> array`
- Delete an element from an array: `delete(array, index) -> array`
- Generate the SHA256 hash of a string: `hash(string) -> string`
- Convert an array into an object: `object(array) -> object`, i.e. the array `(key1, val1, key2, val2)` will result in the object `(key1 => val1, key2 => val2)`
- Convert an object into an array: `array(object) -> array`, i.e. the object `(key1 => val1, key2 => val2)` will result in the array `(key1, val1, key2, val2)`
- List an object's keys: `keys(object) -> array`
- List an object's values: `values(object) -> array`
- Get a list of key-value pairs for an object or array: `pairs(object/array) -> array`, i.e. the object `(key1 => val1, key2 => val2)` will result in `((key1, value1), (key2, value2))`; and the array `(val1, val2)` will result in `((1, val1), (2, val2))`
- Interleave the values of two arrays: `interleave(array) -> array`, i.e. the arrays `(1,2,3)` and `(4,5,6)` will result in `(1,4,2,5,3,6)`
- Make sure an array has no repeated elements: `unique(array) -> array`
- Get the union of two sets: `union(array1, array2) -> array`
- Get the intersection of two sets: `intersection(array1, array2) -> array`
- Get the difference of two sets: `difference(array1, array2) -> array`. Note that changing the order of the parameters can change the result!
- Get the symmetric difference of two sets: `symmetric_difference(array1, array2) -> array`
- Check if two sets are disjoint: `is_disjoint(array1, array2) -> boolean`
- Check if the first set is a subset of the second: `is_subset(array1, array2) -> boolean`
- Check if the first set is a superset of the second: `is_superset(array1, array2) -> boolean`
- Flatten an array of any dimension into a 1D array: `flatten(array) -> array`

Note that functions can be called in one of two ways:
1. The usual syntax, e.g. `split(var, delim)`
2. Using dot-notation, e.g. `var.split(delim)`

Both are exactly equivalent, the latter syntax is included simply for convenience.

### Arrays in expressions
The comma `,` and slice `:` operators always indicate an array.
For example, `(1,2,3)` is an array, as are `(1,2,3,)`, `(1,)` and `(,)`. Note that expressions *are* allowed to have a trailing comma, which simply indicates that the expression is an array with a single element. Likewise, a single comma by itself indicates an empty array.

Note that an expression must contain a comma `,` or slice `:` operator to be considered an array, just parentheses is not enough.
So `(1,)` is an array and `(1:1)` is an equivalent array, but `(1)` is a number, not an array.

Basically, if there's a comma, you have an array.

To access an array's elements, use the usual square-brackets syntax, e.g.
```
let array = {'a', 'b', 'c'}
print {array[1]} #prints "a"
```
And to change an array's elements,
```
let array{2} = 'd' #array is now ('a', 'd', 'c')
let array{-1} = 'e' #array is now ('a', 'd', 'e')
```
You can also append to an array,
```
let array{} = 'f' #array is now ('a', 'd', 'e', 'f')
```

Note that array indexes start at 1, and can be negative to start from the end of the array instead of the beginning (e.g. -1 is the last element, -2 is the second to last, etc).

### Objects in expressions
Objects function very much like JavaScript objects. The keys are always strings, and the values can be anything.
To define an object, just construct a list of key-value pairs, which are any two expressions separated by an arrow, e.g. `"key" => "value"`.
Note that unlike in Lua, you **cannot** mix array and object syntax; it's either one or the other.

Like with arrays, key-value pairs are allowed to have an optional trailing comma.
```
let object = {
	'name' => 'Jerry',
	'age' => 30,
	'friend' => (
		'name' => 'Susan',
		'age' => 35,
	),
}
```
In some cases, it can be useful to create an *empty object*. To do so, just use the arrow operator by itself.
```
let object = {=>}
print {'my object is "' (=>) '"'}
```

Object values can of course be accessed the same way array values can, with the regular indexing `[]` syntax. However, attributes can also be accessed with dot notation.
The following lines do the exact same thing.
```
print {object['name']}
print {object.name}
```

Like with arrays, object values can be added or changed with the following syntax,
```
let object{'name'} = 'Jekyll'
let object{'friend', 'name'} = 'Hyde'
```
However, you cannot use the append syntax on an object, as it does not make sense in that context. So the following will not work:
```
let object{} = 'some value'
```

### List comprehension
Often you need to take an array and mutate every element in some way. While you could very well use a for loop for this, this operation comes up often enough that there is a convenient shorthand for it. See how in the following script, we're taking the array `x` and multiplying every element by `2`, then assigning the result to `y`.
```
let x = {1,2,3}
let y = {,}
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
let y = {,}
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

## Commands

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
For ease of use and consistency, there are 6 built-in commands that will always be the same regardless of what the target environment is.
- `time`: Returns a number representing the clock time. If in a game engine, this is the in-game time. If on PC, this is the same as `systime`. Arguments are ignored.
- `systime`: Returns a number representing the system time (seconds since midnight). Arguments are ignored.
- `sysdate`: Returns a numeric array containing the system day, month, and year (in that order). Arguments are ignored.
- `print`: Prints any params to the 'print' or 'stdout' output.
- `error`: Raises an exception with the line number, message, and stack info. If not caught, outputs the error and ends the program.
- `sleep`: Pause script execution for the given amount of seconds. If the first argument is not a positive number, delay defaults to minimum value (0.02s).

In the PC build, the following commands are also available:
- `clear`: Clears the screen.
- `stdin`: Reads a line of text from stdin.
- `stdout`: Prints text to stdout, without a line ending.
- `stderr`: Prints text to stderr, without a line ending.
- `=`: Executes a unix command, capturing the return value. Run with no params to output the result of the last command.
- `?`: Executes a unix command, capturing the stdout output. Run with no params to output the result of the last command.
- `!`: Executes a unix command, capturing the stderr output. Run with no params to output the result of the last command.
- `?!`: Executes a unix command, capturing both the stdout and stderr output. Run with no params to output the result of the last command.

### Shell command coersion
If the `--shell` or `-l` flag is passed, then Paisley will assume that any undefined commands are programs available on this system.
```
# Plain commands will not capture stdout or stderr, so the following are equivalent:
wget https://127.0.0.1/example
= wget https://127.0.0.1/example

# But inline command evaluation captures stdout, so the following are equivalent:
let x = ${wget https://127.0.0.1/example}
let x = ${? wget https://127.0.0.1/example}
# And NOT equivalent to the following which captures the RETURN value of wget:
let x = ${= wget https://127.0.0.1/example}
```

### Command piping

Like Bash, the stdout of commands can be piped into other commands, or from and to files. This uses the same syntax as bash, for familiarity, and because the syntax is simple enough.
```
echo "some text" > my_file.txt
cat my_file.txt | grep "some"
```
There is one difference however, and it's that the stdout and stderr files are not called `1` and `2` respectively, instead they are `?` and `!` to remain consistent with other syntax. For example, to pipe stderr into a file:
```
wget https://127.0.0.1/example !>my_file.txt
```

## Comments

As mentioned briefly at the top, comments start with `#` and continue until the end of the line.
Comments can also be used to annotate parts of the program and slightly modify compiler behavior.

### Comment annotations

Every comment annotation starts with `@`. They will look something like the following:
```
#Some example subroutine
#@param n number The number to square.
#@return number The square of the input number.
subroutine square
	return {@1 * @1}
end
```

The following is a complete list of annotations and what their effects are:
- `@brief` : Indicate a single-line description of a subroutine, separate from the full description.
- `@param` : Indicate a subroutine parameter of a specific type. This is a type hint and is not enforced.
- `@return` : Indicate a subroutine return value of a specific type.
- `@mutate` : Indicate that this subroutine mutates the given variable(s) (e.g. `#@mutate var1 var2`)
- `@export` : Don't mark this subroutine or variable as dead code. Only used when running Paisley as a language server.
- `@plasma`: Apply the `--plasma` flag to the current compilation unit.
- `@shell`: Apply the `--shell` flag to the current compilation unit.
- `@commands`: Postpone "command not found" errors until run-time, and assume that they return the given types (e.g. `#@commands cmd1:type1 cmd2:type2`)
- `@debug`: Validate command params without actually running them (e.g. `#@debug command_name` ... `#@end`)
