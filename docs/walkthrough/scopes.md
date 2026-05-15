## Scopes:
Every time you enter into a new "block" of code, the scope is incremented.
For global variables this doesn't matter, but macros for example cannot exist outside of the scope where they were defined.
Any structure that naturally isolates a block of code increments the scope.
```
#[[ This is the global scope #]]

while ... do #[[ New scope A #]] end
#[[ Scope A doesn't exist here #]]

for ... do #[[ New scope B #]] end
#[[ Scope B doesn't exist here #]]

if ... then
	#[[ New scope C #]]
elif ... then
	#[[ New scope D. C doesn't exist here #]]
else
	#[[ New scope E. D doesn't exist here #]]
end
#[[ Scopes C, D, E don't exist here #]]

match ... do
	if ... then #[[ New scope F #]] end
else
	# You get the picture
end

function my_sub
	# You guessed it! This function has its own scope.
end

try
	# Scope F
except err
	# Scope G
end
```

In some cases, you may want to intentionally create a scope to isolate a block of code. You can do so with the `do ... end` block:
```
# The real value for pi is about 3.14
define {!pi[3.14]}

do
	# But sometimes, 3 might be a good enough estimate
	define {!pi[3]}

	print "My estimate for pi is {!pi}"
end

print "The real value of pi is {!pi}"
```
---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: [exceptions.md]
[next]: [misc_statements.md]
