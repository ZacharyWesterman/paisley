### List comprehension
Often you need to take an array and mutate every element in some way. While you could very well use a for loop for this, this operation comes up often enough that there is a convenient shorthand for it. See how in the following script, we're taking the array `x` and multiplying every element by `2`, then assigning the result to `y`.
```
let x = {1,2,3}
let y = {,}
for i in {x} do
	let y{} = {i * 2}
end
```
The above could be written much more succinctly as the following:
```
let x = {1,2,3}
let y = {i * 2 for i in x}
```

Those of you familiar with Python will realize where the syntax comes from, and like in Python, you can filter out array elements based on a condition. See how in the following script, `x` is all numbers from 1 to 100, and we're selecting only those numbers divisible by `5`, and storing the result in `y`.
```
let x = {1:100}
let y = {,}
for i in {x} do
	if {i % 5 = 0} then
		let y{} = {i}
	end
end
```
The above could instead be written as the following:
```
let x = {1:100}
let y = {i for i in x if i % 5 = 0}
```

One important caveat to note about list comprehension is that the intermediate variable does not actually change the values of any global variables.
So, while the above examples are *computationally* the same, list comprehension has the benefits of being more terse, more performant, and encapsulated.
For example,
```
let i = 123
let values = {i + 1 for i in 0:9}
print {i} # This is still `123`! The list comprehension did not affect the actual variable `i`.
```

---

{% shared.navigate %}

[prev]: [objects.md]
[next]: [commands.md]
