## Conditionals:
"If" statements have the following structure:
```pai
if {expression is truthy} then
	# ...
elif {expression is truthy} then
	# ...
else
	# ...
end
```

You can also leave out the "then" clause if all that's needed is the "else" clause, e.g.:
```pai
if {expression is truthy} else
	# ... do this if expression is falsey ...
end
```

Keep in mind that `if` statements convert the expression to a boolean, and so use a few rules to test an expression's truthiness: false, null, zero, empty strings, empty arrays and empty objects are all falsey, everything else is truthy.
See [the type-casting docs](../type-casting.md) for more info on truthiness and other type-casting rules.

There is also the `match` structure, which is similar to c-like languages' `switch/case` structure (or Rust's `match`). This structure is included to allow for more readable logic with less repeated code.
```pai
match {expression} do
	action1 if {case 1}
	action2 if {case 2}
	if {case 3} then #[[...complex logic, loops, etc...#]] end
	# ...
else
	# ... default action if no cases match ...
end
```
For example:
```pai
match {random_int(1,5)} do
	print one if 1
	print two if 2
	print "4 or 5" if {> 4}
	if {like '%d+'} then error "it's a string?!" end
else
	print "some other number"
end
```

See how there are two possible syntaxes for the match branches.
The first kind, `{command(s)} if {expression}` only allows a list of simple commands, that is, any block statements (e.g. `if`, `while`, etc.)are **not allowed**, however, multiple commands are fine (e.g. `print 123; stop if {> 4}` is fine).
The second kind, `if {expression} then {command(s)} end` functions like a normal if statement; it allows any kind of statement(s) to be used inside.

Note that, inside match statements, the top-level boolean operators (`=`, `!=`, `>`, `<`, `>=`, `<=`, `in`, `like`, `and`, `or`, `xor`, `%%`) and bitwise operators (`bitwise and`, `bitwise or`, `bitwise xor`) don't require a left operand.
Instead, the left operand is implied to be the bound value of the match expression.
If the operator is left out, then `=` is implied. e.g. `{3}` is the same as `{=3}`.

Of course, like `if` statements, the `else` branch is optional and can be excluded.

---

### < Prev | [Home](../walkthrough.md) | [Next >][next]

[next]: loops.md
