## User-defined functions:
User-defined functions may be either called as if they were commands, or built-in functions.
Like commands, they can take parameters and optionally return a value, but they don't have to.
Unlike commands, they can modify global variables, which may or may not be desired. Just keep it in mind when writing them.

An example function definition and usage might look like the following:
```pai
function print_numbers
	for i in {0 : @[1]} do
		if {i > 30} then
			print "whoa, too big!"
			return
		end
		print {i}
	end
end

call print_numbers 10
call print_numbers 50

function power
	return {@[1] ^ @[2]}
end

# You can use call the same as any inline command evaluation.
print ${call power 2 10}

# However, for calling user-defined functions inside expressions, they can be used like built-in functions!
# Just prepend a backslash to the function name.
print {\power(2,10)}
```
See how in the above, the `@` variable stores any parameters passed to a function as an array, so the first parameter is `@[1]`, the second is `@[2]` and so on. For constant indexes, the square brackets are optional, e.g. `@1` and `@2` will also work, but **not** `@ 2`.
Also see that functions return values the same way that commands do, using the inline command evaluation syntax, `${...}`.

### Dynamic Dispatch

Note that it is also possible to jump to functions with an arbitrary label ID. Unlike a regular call, a dynamic call could fail at runtime due to the function not existing, and so requires a conditional check `if call {expression} then ... else ... end` to make sure the function call is valid.
See how in the following example, the program will randomly call one of 5 possible functions, and then print "Function exists".
```pai
if call "{random_int(1,5)}" then
	print "Function exists"
end

function 1 end
function 2 end
function 3 end
function 4 end
function 5 end
```

You can of course also pass arguments to a dynamic call.
However, any returned value is ignored.

```pai
if call "add{random_int(1,5)}" 100 then
	print "Function exists"
end

function add1
	print {@1 + 1}
end
...
function add5
	print {@1 + 5}
end
```

As an aside, note how in the above, the function calls happened *before* their definitions.
This is totally valid; as long as the function is defined *somewhere*, the compiler doesn't care *where* it's defined.

### User-defined Functions in Expressions:
Inside of expressions, functions can be called in one of two ways:

1. Using the inline command evaluation syntax `${...}`, in the same way as commands are used. E.g. `${call my_function {arg1} arg2 "arg3" etc..}`
2. Using the special function evaluation syntax `\my_function(arg1,arg2,etc...)`. Note that calling functions like this ignores other syntax until the parentheses. So calling `\some.sub.name(arg1)` or `\+(123, 456)` will always be interpreted as function calls.

These both do exactly the same thing: the latter is just syntax sugar for the former, and is supplied for convenience.

### Function Memoization:
Some functions may take a very long time to compute values, when we only really need them to be computed once for any given input.
For these kinds of functions, the `cache` keyword can be used to memoize the function and only compute the results once.
See the following recursive fibonacci example:
```pai
cache function fib
	if {@1 < 2} then return {@1} end
	return {\fib(@1 - 1) + \fib(@1 - 2)}
end
```
Subsequent calls to `fib` will be *very* fast, because each fibonacci number only has to be computed once.

If it turns out that you need to invalidate a specific function's cache, you can manually do so:
```pai
break cache fib
```
If the function is not memoized, this of course does nothing.

In short, memoization can be a good way to get a significant performance boost, basically for free (there *is* a slight runtime overhead, but it's negligible). Do keep in mind that any side effects (e.g. running commands, modifying variables, etc) of the called function will not trigger if the result is already cached, so do not use this feature if you *want* your function to always cause side effects.

### Function Aliases:

Some functions may have very long names that are unwieldy to type. In such cases you can create an alias with the `using` keyword:
```pai
function very_long_name_thats_annoying_to_type end
using very_long_name_thats_annoying_to_type as short_name
call short_name

#If your function name has at least one period in it,
#then you don't have to manually write the alias name.
#It will be deduced from the text after the last period.
function example.sub end
using example.sub
call sub
```
Do note that aliases are restricted to their scope, for example:
```pai
function example.sub end
if {x} then
	using example.sub as mysub
	call mysub #This is valid.
end
call mysub #This is an error; "mysub" alias is not defined in this scope.
```
You can also alias functions according to a wildcard, if you end the function name with an asterisk.
```pai
function sub1 end
function sub2 end
using sub* as * #Can now do `call 1` and `call 2`
using sub* as s* #Can now do `call s1` and `call s2`
using sub* as *s #Can now do `call 1s` and `call 2s`
using nonexistent.sub.* #Nothing happens unless at least 1 function matches the pattern.
```
Note that aliases do NOT work with dynamic calls; those require the full function name, to avoid any ambiguity at runtime.

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: variables.md
[next]: macros.md
