# Objects

Objects function much like JavaScript objects in the sense that they are just a collection of key-value pairs, where the keys are always strings, and the values can be anything.
Like tables in Lua, the keys of an object *are not guaranteed to be in any order*, and setting a value in an object to `null` deletes it from the object.
However, objects differ from Lua tables in two major ways:
1. The keys are always strings. If you use a key that is not a string, it will be cast to one using [Paisley's type-casting rules](docs/type-casting.md).
2. You **cannot** mix array and object construction syntax; it's either one or the other. (e.g. `{"a" => 123, "b"}` is not allowed!)

To define an object, use the arrow operator `=>` between two values, such as `"key" => 123` or `var => 123`. 
Like with arrays, key-value pairs are allowed to have an optional trailing comma.
```
let object = {
	'name' => 'Jerry',
	'age' => 30,
	'friend' => (
		'name' => 'Susan',
		'age' => 35,
	),
}
```
To create an empty object, just use the arrow operator by itself.
```
let object = {=>}
let array_of_empties = {
	(=>),
	(=>),
	(=>),
}
```

Object values can of course be accessed the same way array values can, with the regular indexing `[]` syntax.
However, attributes can also be accessed with dot notation if they contain only alphanumeric characters
(that is, they match the pattern `[a-zA-Z_][0-9a-zA-Z_]*`).
The following lines do the exact same thing.
```
print {object['name']}
print {object.name}
```

Like with arrays, object values can be added or changed with the following syntax,
```
let object{'name'} = 'Jekyll'
let object{'friend', 'name'} = 'Hyde'
```
However, you cannot use the append syntax on an object, as it does not make sense in that context. So the following will not work:
```
let object{} = 'some value'
```

## Truthiness

If an object contains any values, it is `truthy`.
Empty objects are `falsey`.
