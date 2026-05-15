## Macros:
Macros are another good way to reuse code, however unlike functions, these are specifically for reusing parts of expressions.
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

Another fun use of macros is the ability to create auto-incrementing values that are resolved at compile time:
```
define {![0]}
let a = {![!+1]} # `a` is set to 1.
let b = {![!+1]} # `b` is set to 2.
let c = {![!+1]} # `c` is set to 3.
```

Note that, unlike variables, macros are restricted to their scope. Thus, for example, if you define a macro in a function, you cannot use it outside of the function.

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: functions.md
[next]: exceptions.md
