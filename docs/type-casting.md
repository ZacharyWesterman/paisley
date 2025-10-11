# Type Casting

Paisley does not coerce values to other types, except in the case of conditionals, where types are coerced into booleans.

In all other cases, values must be manually cast to different types by the programmer.

### Casting to strings

- null - converts to an empty string `""`.
- true and false - convert to `"1"` and `"0"` respectively.
- numbers - convert to the usual decimal text representation.
- arrays - for historical reasons, arrays are cast to space-delimited strings, e.g. `("a",123,"b")` is converted to `"a 123 b"`.
- objects - for historical reasons, objects' values and keys are cast to space delimited strings, e.g. `{"a" => 1, "b" => 2}` is converted to `"a 1 b 2"`

### Casting to numbers

- null - converts to zero
- true and false - convert to `1` and `0` respectively.
- strings - convert to zero if not numeric, otherwise are converted using the usual decimal text representation.
- arrays - always convert to zero.
- objects - always convert to zero.

### Casting to booleans

- null - converts to `false`
- numbers - zero converts to `false`, anything else is `true`.
- strings - empty strings convert to `false`, anything else is `true`.
- arrays - empty arrays convert to `false`, anything else is `true`.
- objects - empty objects convert to `false`, anything else is `true`.
