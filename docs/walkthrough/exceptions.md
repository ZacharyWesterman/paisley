## Exceptions:
Sometimes, parts of a program **will** fail, and the failure point is not always easy to predict. Paisley handles this with exceptions. To raise an exception, use the `error` statement along with any message, and an optional `as <exception_type>` at the end. See the following example:

```
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
```
{
	"message": "your error message",
	"line": 6,
	"stack": [2, 6],
	"type": "exception_type",
}
```
Where `line` is the line where the exception was caught, and `stack` is the line numbers for the function call stack.

This is just a basic overview of error handling with exceptions. There are more features than are written here, so I do recommend you [take a quick peek at the docs](exceptions.md) for a more detailed breakdown.

---

{% shared.navigate %}

[prev]: [macros.md]
[next]: [scopes.md]
