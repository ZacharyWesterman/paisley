## Exceptions:
Sometimes, parts of a program **will** fail, and the failure point is not always easy to predict. Paisley handles this with exceptions. To raise an exception, use the `error` statement along with any message, and an optional `as <exception_type>` at the end. See the following example:

```pai
function this_errors
	error "your error message"
end

try
	call this_errors
catch exception as ex
	# Caught error will land here
	print "Exception caught: {json_encode(ex)}"
end
```
The output variable (in this case `ex`) will always be an object that looks like the following:
```pai
{
	"message": "your error message",
	"line": 6,
	"stack": [2, 6],
	"type": "exception_type",
}
```
Where `line` is the line where the exception was caught, and `stack` is the line numbers for the function call stack.

## Throwing exceptions

To throw an exception, use one of following syntaxes:
```pai
error "Some error message" as exception_type
error "Some error message"
```
The latter is the same as `error "Some error message" as exception`.

The exception type can be anything; it's basically just a flag for later catching.

## Catching exceptions

The basic syntax for catching errors is:
```pai
try
	# Some code here
catch exception_type as variable
	# Handle the error
end
```

However,

- There can be any number of `catch` blocks.
- Each `catch` block can catch any number of exception types.
- The captured variable is optional, and may be excluded.

So the following is totally valid:
```pai
try
	# Some code here
catch exception math_error network_error
	# Ignore these
catch invalid_os_error as err
	print "Exception caught: {err.json_encode()}"
end
```

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: macros.md
[next]: scopes.md
