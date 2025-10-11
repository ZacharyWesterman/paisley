# Arrays

Arrays function much like arrays in other languages, with one caveat: **null values are not allowed in arrays**. This has to do with the oddities of Lua's `nil` in tables, so to avoid having to handle it, they're just not allowed when constructing arrays.

Like in Lua, **arrays are 1-indexed**.

The comma `,` and slice `:` operators always indicate an array.
For example, `(1,2,3)` is an array, as are `(1,2,3,)`, `(1,)` and `(,)`. Note that expressions *are* allowed to have a trailing comma, which simply indicates that the expression is an array with a single element. Likewise, a single comma by itself indicates an empty array.

Note that an expression must contain a comma `,` or slice `:` operator to be considered an array, just parentheses is not enough.
So `(1,)` is an array and `(1:1)` is an equivalent array, but `(1)` is a number, not an array.

Basically, if there's a comma, you have an array.

## Constructing Arrays
Here are some example array constructions:
```
let array = {
	"a",
	123,
	true,
}
let numbers = {0:9} #Contains (0, 1, 2, ... 8, 9)
let empty_array = {,}
let one_element_array = {123,} #That comma is necessary!
let nested_1_elem_array = {(123,),} #This is an array with 1 element. That element is an array with 1 element.

#You can also mix slices and single elements!
let array_mix = {
	1,
	5,
	10:15,
	100,
	500,
} #Contains (1, 5, 10, 11, 12, 13, 14, 15, 100, 500)
```

## Accessing Array Elements
To access an array's elements, use the usual square-brackets syntax seen in most languages, e.g.
```
let array = {'a', 'b', 'c'}
print {array[1]} #prints "a"
```
And to change an array's elements,
```
let array{2} = 'd' #array is now ('a', 'd', 'c')
let array{-1} = 'e' #array is now ('a', 'd', 'e')
```
You can also append to an array,
```
let array{} = 'f' #array is now ('a', 'd', 'e', 'f')
```

Keep in mind that array indexes start at 1, and can be negative to start from the end of the array instead of the beginning (e.g. -1 is the last element, -2 is the second to last, etc).

## Truthiness

If an array contains any values, it is `truthy`.
Empty arrays are `falsey`.
