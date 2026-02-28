# Debug Comment Annotations

Debug annotations are a powerful tool that allows for compile-time validation of the usage of commands or user-defined functions.
This validation is performed with an arbitrary Lua script inside the comment, giving the programmer the ability to perform nearly any sort of analysis on functions or commands.

For security purposes, all debug annotations are entirely sandboxed. That is, they do not have access to `io`, `os`, or `require`, and the global variable `_G` is entirely empty.

Additionally, debug annotations *can never* emit errors, and since warnings can be promoted to errors with the `--werror` flag, they cannot emit warnings either.
The only compiler message that can be emitted is "info" level messages, or using Lua's `print()` function.

There are 3 flavors of debug annotations. All start with `@debug`
1. Command debugging
2. In-place function debugging
3. Imported function debugging

## Command debugging

Debug annotations for commands must start with `@debug` some identifier, and continue until `@end` is reached.
The identifier can contain anything except `{}$()` or whitespace.
These annotations can go anywhere, and will apply to all uses of the command.

Below is an example debug annotation that could be used to verify arguments passed to the `sleep` command.

```
#[[
@debug sleep (args, info, json)
	-- Even though `sleep` command is syntactically allowed to have any number
	-- of arguments passed to it (as are all commands),
	-- It really should only be given exactly one.
	if #args ~= 1 then
		info('Expected 1 argument, but got' .. #args .. '.')
		return
	end

	-- If the type is `unknown`, then we don't know if it's invalid or not.
	if not args[1].type then return end

	-- Users should only pass a number, or at least a value that *may be* a number.
	-- E.g. if they pass some value of type `number|string|null`, then that's valid,
	-- but passing a value of type `string|null` is invalid, because it's for sure not a number.
	if not args[1].type:is_superset_of('number') then
		args[1].info(
			'Argument of type `' ..
			args[1].type:tostring() ..
			'` is incompatible with `number`.'
		)
	end
@end
#]]
```

## Function debugging

### In-place debug annotations:

The syntax for function debug annotations is very similar to that of command annotations, except that there is no identifier in the annotation.
Additionally, unlike the command annotations, these must go in comments directly above a function, as you would for any other annotations that are meant to apply to the function.

So an example annotation could be something like:

```
#[[
@debug (args, info, json)
	--This function should not take any arguments
	if #args > 0 then
		info('Function expects zero arguments, but ' .. #args .. ' given.')
	end
@end
#]]
function no_args
	# Function body goes here
end
```

### Imported debug annotations:

Writing annotations like the above, while useful, do tend to clutter up the function's documentation or other annotations, not to mention that if you want to use the annotation on multiple functions, you have to duplicate it each time.

To solve this, you can import annotations using `@debug {lua.import.path}` (no `@end` in this case).
This import path is relative to the current script, or the stdlib if not found at the aforementioned.
The imported file is just a normal lua script that returns a function.

So for example, you could implement the above `no_args` function and annotation with something like the given directory structure:

```
project/
├─ main.pai
└─ annotations/
   └─ no_args.lua
```

#### main.pai
```
# @debug {annotations.no_args}
function no_args
	# Function body goes here
end
```

#### annotations/no_args.lua
```lua
return function (args, info, json)
	--This function should not take any arguments
	if #args > 0 then
		info('Function expects zero arguments, but ' .. #args .. ' given.')
	end
end
```

Obviously, the exact file structure is up to you, but that would be a totally fine way to structure it.
And the benefits here are that not only do the annotations themselves take up very little space, but they are easy to reuse, and if you need to change the annotation's behavior, you don't have to change a million source files, only one.
