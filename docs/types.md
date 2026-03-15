# Data Types

Paisley has 6 data types:
- object
- array
- string
- number
- boolean
- null

Of those, `object` and `array` may have sub-types depending on what values they contain.
The only exception is that objects and arrays may **not** contain `null` values.
Setting a value to null will simply delete if from an object, or do nothing in an array.


There is also another pseudo-type, which means that the actual type could be anything:
- any

When representing types, the compiler will use syntax like the following:
`TYPE1|TYPE2[SUBTYPE1|SUBTYPE2]`
which means that the value may be of type `TYPE1` or `TYPE2`,
and that type2 has sub-values, which may be of type `SUBTYPE1` or `SUBTYPE2`.
The subtype is optional, and if not specified, will be assumed to be `any`.
- `[...]`: Contains sub-values of the following type(s).
- `A|B`: Type A or B, (can chain, like `A|B|C` to mean A or B or C).
- `A?`: Shorthand for `A|null`.

For example, `string|number|array` would mean that the type may be a string, a number, or an array whose values could be anything.
Likewise, `object[boolean]?` means that the type may be either null, or an object that only contains booleans.
