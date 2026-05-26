## Variable Assignment:
Variable assignment always starts with `let`, e.g.
```pai
let pi = 3.14
let circumference = {2 * pi * r}
```
Note that the `let` keyword is required even when reassigning variables.
For example, consider the following:
```pai
let var = 13
var = 99
```
The second line will **NOT** set var's value to 13. Instead, that would attempt to run a command called "var" with the parameters `["=", "99"]`.

Of course, sometimes a variable will contain an array that you don't want to overwrite, instead you just want to update a *single element* or *append* to the array.
The following will result in var containing the array `(1, 2, 123, 4, 99)`. Note that giving negative values as the index will start counting from the end, so index of -1 will update the last element.
```pai
let var = 1 2 3 4 5
let var{3} = 123
let var{-1} = 99
```

Appending is just as simple. The following will result in var containing the array `(1, 2, 3, 4, 5, 6)`.
```pai
let var = 1 2 3 4 5
let var{} = 6
```

And if you want to append to a sub-value of some object, use both of the above two syntaxes.
```pai
let var = {"a" => (1,2,3)}
let var{"a"}{} = 4
```

You can also assign multiple variables at the same time.
```pai
let a b c = 1 2 3

#Alternatively, you can assign variables from values in an array
let list = {1:9}
let a b c = {list}
```

To simply define a variable as null, you can just leave off the expression. The following all initialize variables as null.
```pai
let var
let a b c
let foo = {null}
```

Like in other languages, there is also a shorthand syntax for reassigning a variable based on its previous value:
```pai
let x += 1 # Add 1 to x
let x -= 1 # Subtract 1 from x
let x *= 2 # Multiply x by 2
let x /= 2 # Divide x by 2
let x //= 2 # Integer-divide x by 2
let x %= 2 # Set x to the remainder of x / 2
let x %%= 2 # Set x to true if 2 divides x, false otherwise.
let x &= str # Append "str" to x
```

### Variable Index Assignment

Assignment of arrays, strings and objects can all be indexed to only alter sub-elements.
As mentioned above, this uses the `let var{expr} = expr` syntax.

However, some objects may be more deeply nested. For example, suppose you have a 2D array or a complex object:
```pai
let array = {
	[1, 2, 3],
	[4, 5, 6],
}
let object = {
	"a" => {
		"b" => {
			"c" => 123,
		}
	}
}
```

If you want to change `array[1][2]` from `2` to `8`, or `object.a.b.c` from `123` to `456`, just add extra values in the index field, separated by commas:
```pai
let array{1, 2} = 8
let object{'a', 'b', 'c'} = 456

# The {...} indexing syntax above allows for arbitrary expressions,
# but if the indexes are known at compile time, there's a simple shorthand:
let array.1.2 = 8
let object.a.b.c = 456

# You can of course mix and match.
let array.1{2} = 8
let object.a.b{'c'} = 456
let array.1{} = 4
```

**REMEMBER:** All variables are global, so any "re-definition" of a variable just sets it to the new value.

### Variable Initialization:

There is a special keyword for setting a variable's value if it hasn't been assigned already.
```pai
initial variable = {value}
```
Unlike the `let` keyword, `initial` can only define one variable, and it cannot insert or update sub-elements in arrays. The use of `initial` is instead a concise way to set a default value for un-initialized variables. Logically, it is identical to the following:
```pai
if {not (variable exists)} then
	let variable = {value}
end
```

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: loops.md
[next]: functions.md
