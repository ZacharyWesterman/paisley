## Loops:
While and For loops each have two variations:
```pai
# While loop
while {expression is truthy} do
	...
end

# Infinite loop
while do
	...
end

# Iterator for loop
for value in {expression} do
	...
end

# Key-value for loop
for key value in {pairs(object or array)} do
	...
end
```

Note that the iterator (2nd from the bottom) loop type will iterate over all *values* in an array, and all *keys* in an object!
Also note that the key-value (bottom) loop **must** contain either `pairs()` or `chunk(2)`, to ensure that the key-value pairs are valid.

If you want syntax similar to Lua's integer for loops (`for i = 1, 10 do ... end`), you can use something like `for i in {1:10} do ... end`.

### Scalar values in for loops
If a for loop is given a non-array-or-object expression, it will be coerced into an array based on the type:

Strings will be split by newline (`\n`) character. This makes it trivial to iterate over lines that a command output, lines in a file, etc.
Numbers or booleans will be converted to an array with 1 element, namely the expression value.
Null will be converted to an empty array.

### Generator-exception loops

A common pattern is to use exceptions to give generator behavior. For example, suppose you have a function that generates numbers from 0-9, and then raises an exception when done, to indicate there is no more data that can be generated:
```pai
function next
	initial i = {-1}
	if {i >= 10} then
		error 'End of generator' as generator_end
	end
	let i += 1
	return {i}
end
```

This can easily be handled with
```pai
try
	while {true} do
		print "Generated item: {\next()}"
		# Do other stuff
	end
catch generator_end
end
```

While that works, it's not immediately obvious that you're just looping until the generator is empty.
So, there is syntax sugar that does the same thing but is more explicit about it:
```pai
until generator_end do
	print "Generated item: {\next()}"
	# Do other stuff
end
```

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: conditionals.md
[next]: variables.md
