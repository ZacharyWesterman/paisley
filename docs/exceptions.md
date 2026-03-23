# Exceptions

## Throwing exceptions

To throw an exception, use one of following syntaxes:
```
error "Some error message" as exception_type
error "Some error message"
```
The latter is the same as `error "Some error message" as exception`.

The exception type can be anything; it's basically just a flag for later catching.

## Catching exceptions

The basic syntax for catching errors is:
```
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
```
try
	# Some code here
catch exception math_error network_error
	# Ignore these
catch invalid_os_error as err
	print "Exception caught: {err.json_encode()}"
end
```
