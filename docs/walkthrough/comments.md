## Comments

As mentioned briefly at the beginning, single-line comments start with `#` and continue until the end of the line,
and multi-line comments start with `#[[` and continue until `#]]`.
Comments can also be used to annotate parts of the program and slightly modify compiler behavior.

### Comment annotations

Every comment annotation starts with `@`. They will look something like the following:
```
#Some example function
#@param n number The number to square.
#@return number The square of the input number.
function square
	return {@1 * @1}
end
```

The following is a complete list of annotations and what their effects are:
- `@file` : A description for the current file. This can be multi-line, continuing until the end of the comment.
- `@brief` : A single-line description of a function or variable.
- `@param` : Indicate a function parameter of a specific type.
- `@return` : Indicate a function return value of a specific type.
- `@type`: Indicate that the variable is guaranteed to have the given data type.
- `@allow_elision`: Allow this function to be overridden by external code.
- `@export` : Don't mark this function or variable as dead code. Only used when running Paisley as a language server.
- `@shell`: Apply the `--shell` flag to the current compilation unit.
- `@sandbox`: Apply the `--sandbox` flag to the current compilation unit. Overrides `--shell`.
- `@plasma`: Apply the `--plasma` flag to the current compilation unit. Overrides `--shell` and `--sandbox`.
- `@commands`: Postpone "command not found" errors for the given command(s) until run-time, and assume that they return the given types (e.g. `#@commands cmd1:type1 cmd2:type2`)
- `@debug`: Validate command or function arguments at compile time (e.g. `#@debug command_name` ... `#@end`). see the [docs on debug annotations](../debug_annotations.md) for more info.

---

{% shared.navigate %}

[prev]: [commands.md]
[next]: [directives.md]
