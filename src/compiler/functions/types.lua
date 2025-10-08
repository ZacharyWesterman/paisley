--Specify the type signature for every function and operator
--Also specify help info if not the Plasma build.
TYPESIG = {
	random_int = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'min', 'max' },
		description = 'Generate a random integer from min to max (inclusive) with uniform distribution.',
		category = 'randomization',
		--[[/minify-delete]]
	},
	random_float = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'min', 'max' },
		description = 'Generate a random real number from min to max (inclusive) with uniform distribution.',
		category = 'randomization',
		--[[/minify-delete]]
	},
	random_element = {
		valid = { { 'array' } },
		out = 'any',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Select a random element from a list with uniform distribution.',
		category = 'randomization',
		--[[/minify-delete]]
	},
	word_diff = {
		valid = { { 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'word1', 'word2' },
		description =
		'Get the levenshtein difference between two strings. See https://en.wikipedia.org/wiki/Levenshtein_distance for more information.',
		category = 'strings',
		--[[/minify-delete]]
	},
	dist = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'point1', 'point2' },
		description = 'Get the euclidean distance between numbers or vectors of the same dimension',
		category = 'arrays:vectors',
		--[[/minify-delete]]
	},
	sin = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the sine of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	cos = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the cosine of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	tan = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the tangent of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	asin = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the arcsine of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	acos = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the arccosine of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	atan = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the arctangent of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	atan2 = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x', 'y' },
		description = 'Calculate the signed arctangent of y/x.',
		category = 'math',
		--[[/minify-delete]]
	},
	sqrt = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the square root of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	bytes = {
		valid = { { 'number' } },
		out = 'array[number]',
		--[[minify-delete]]
		params = { 'value' },
		description = 'Split a number into bytes. The number is interpreted as an unsigned 32-bit integer.',
		category = 'characters',
		--[[/minify-delete]]
	},
	frombytes = {
		valid = { { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'bytes' },
		description =
		'Convert a list of bytes into a number. The resultant number is constructed as an unsigned 32-bit integer.',
		category = 'characters',
		--[[/minify-delete]]
	},
	sum = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Calculate the sum of a list of values. This is identical to calling `reduce(..., +)`.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	mult = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Calculate the product of a list of values. This is identical to calling `reduce(..., *)`.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	min = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Find the minimum of a list of values.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	max = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Find the maximum of a list of values.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	clamp = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'value', 'min', 'max' },
		description = 'Keep a value inside the given range.',
		category = 'math',
		--[[/minify-delete]]
	},
	smoothstep = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'value', 'min', 'max' },
		description = 'Smoothly transition from 0 to 1 in a given range.',
		category = 'math',
		--[[/minify-delete]]
	},
	lerp = {
		valid = { { 'number' }, { 'number', 'array[number]', 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'ratio', 'start', 'end' },
		description = 'Linearly interpolate between two numbers or vectors.',
		category = 'math',
		--[[/minify-delete]]
	},
	split = {
		valid = { { 'string', 'string' } },
		out = 'array[string]',
		--[[minify-delete]]
		params = { 'text', 'delim' },
		description =
		'Split a string into an array based on a delimiter. If the delimiter is an empty string, the string is split into individual characters.',
		category = 'strings',
		--[[/minify-delete]]
	},
	join = {
		valid = { { 'array', 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'list', 'delim' },
		description = 'Join an array into a single string with a delimiter between elements.',
		category = 'strings',
		--[[/minify-delete]]
	},
	count = {
		valid = { { 'array', 'any' }, { 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'iter', 'value' },
		description = 'Count the number of occurrences of a value in an array or string.',
		category = 'iterables',
		--[[/minify-delete]]
	},
	index = {
		valid = { { 'array', 'any' }, { 'string', 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'iterable', 'value' },
		description = 'Find the index of the first occurrence of a value in an array or string.',
		category = 'iterables',
		--[[/minify-delete]]
	},
	find = {
		valid = { { 'array', 'any', 'number' }, { 'string', 'string', 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'iterable', 'value', 'occurrence' },
		description = 'Find the index of the nth occurrence of a value in an array or string.',
		category = 'iterables',
		--[[/minify-delete]]
	},
	type = {
		out = 'string',
		--[[minify-delete]]
		params = { 'data' },
		description =
		'Get the data type of a value. Possible return values are "number", "string", "boolean", "null", "array" or "object".',
		category = 'types',
		--[[/minify-delete]]
	},
	bool = {
		out = 'boolean',
		--[[minify-delete]]
		params = { 'data' },
		description =
		'Convert a value to a boolean. Returns false for null, 0, empty strings, empty arrays, and empty objects. All other values return true.',
		category = 'types',
		--[[/minify-delete]]
	},
	num = {
		out = 'number',
		--[[minify-delete]]
		params = { 'data' },
		description =
		'Convert a value to a number. Returns 1 for true, and if a string is numeric, returns the number. All other non-number values return 0.',
		category = 'types',
		--[[/minify-delete]]
	},
	int = {
		out = 'number',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Convert a value to an integer. Converts a value to a number, then floors it.',
		category = 'types',
		--[[/minify-delete]]
	},
	str = {
		out = 'string',
		--[[minify-delete]]
		params = { 'data' },
		description =
		'Convert a value to a string. Null is converted to an empty string, and booleans are converted to a 1 or 0. Arrays are joined into a space-separated list like "value1 value2 etc", and objects are joined in a similar fashion e.g. "key1 value1 key2 value2 etc".',
		category = 'types',
		--[[/minify-delete]]
	},
	floor = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Round down to the nearest integer.',
		category = 'math',
		--[[/minify-delete]]
	},
	ceil = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Round up to the nearest integer.',
		category = 'math',
		--[[/minify-delete]]
	},
	round = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Round to the nearest integer.',
		category = 'math',
		--[[/minify-delete]]
	},
	abs = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Get the absolute value of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	append = {
		valid = { { 'array', 'any' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'value' },
		description = 'Append a value to an array.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	lower = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert a string to lowercase.',
		category = 'strings',
		--[[/minify-delete]]
	},
	upper = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert a string to uppercase.',
		category = 'strings',
		--[[/minify-delete]]
	},
	camel = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Capitalize the first letter of every word.',
		category = 'strings',
		--[[/minify-delete]]
	},
	replace = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'search', 'replace' },
		description = 'Replace all occurrences of a substring.',
		category = 'strings',
		--[[/minify-delete]]
	},
	json_encode = {
		valid = { { 'any', 'boolean' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Serialize data to a JSON string.',
		category = 'encoding',
		--[[/minify-delete]]
	},
	json_decode = {
		valid = { { 'string' } },
		out = 'any',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Deserialize data from a JSON string.',
		category = 'encoding',
		--[[/minify-delete]]
	},
	json_valid = {
		out = 'boolean',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Check if a JSON string is formatted correctly.',
		category = 'encoding',
		--[[/minify-delete]]
	},
	b64_encode = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert a string to base64.',
		category = 'encoding',
		--[[/minify-delete]]
	},
	b64_decode = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert base64 text to a string.',
		category = 'encoding',
		--[[/minify-delete]]
	},
	lpad = {
		valid = { { 'string', 'string', 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'pad_char', 'width' },
		description = 'Left-pad a string with a given character.',
		category = 'strings',
		--[[/minify-delete]]
	},
	rpad = {
		valid = { { 'string', 'string', 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'pad_char', 'width' },
		description = 'Right-pad a string with a given character.',
		category = 'strings',
		--[[/minify-delete]]
	},
	hex = {
		valid = { { 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'value' },
		description = 'Convert a number to a hexadecimal string. This is identical to `to_base(value, 16, 0)`.',
		category = 'strings',
		--[[/minify-delete]]
	},
	filter = {
		valid = { { 'string', 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'valid_chars' },
		description = 'Remove all characters that do not match the given pattern.',
		category = 'strings',
		--[[/minify-delete]]
	},
	matches = {
		valid = { { 'string', 'string' } },
		out = 'array[string]',
		--[[minify-delete]]
		params = { 'text', 'pattern' },
		description = 'Get all substrings that match the given pattern.',
		category = 'strings',
		--[[/minify-delete]]
	},
	clocktime = {
		valid = { { 'number' } },
		out = 'array[number]',
		--[[minify-delete]]
		params = { 'timestamp' },
		description = 'Convert a "seconds since midnight" timestamp into (hour, min, sec, milli).',
		category = 'time',
		--[[/minify-delete]]
	},
	reduce = {
		valid = { { 'array', 'any' } },
		--[[minify-delete]]
		params = { 'list', 'op' },
		description =
		'Reduce an array to a single element based on a repeated binary operation. Valid operators are: +, -, *, /, %, //, and, or, xor.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	reverse = {
		valid = { { 'array' }, { 'string' } },
		out = 1, --output type is the same as that of the first parameter
		--[[minify-delete]]
		params = { 'iter' },
		description = 'Reverse an array or a string.',
		category = 'iterables',
		--[[/minify-delete]]
	},
	sort = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Sort an array in ascending order.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	merge = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list1', 'list2' },
		description = 'Concatenate two arrays together.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	update = {
		valid = { { 'array', 'number', 'any' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'index', 'new_value' },
		description =
		'Replace an element in an array at the given index. If the index is out of bounds, the original array is returned.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	insert = {
		valid = { { 'array', 'number', 'any' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'before_index', 'value' },
		description =
		'Insert an element in an array at the given index. If the index is out of bounds, then the value will either be added to the beginning or the end of the array.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	delete = {
		valid = { { 'array', 'number' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'index' },
		description =
		'Delete an element from an array at the given index. If the index is out of bounds, the original array is returned.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	hash = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Generate the SHA256 hash of a string.',
		category = 'miscellaneous',
		--[[/minify-delete]]
	},
	object = {
		valid = { { 'array' } },
		out = 'object',
		--[[minify-delete]]
		params = { 'list' },
		description =
		'Convert an array into an object. The array is assumed to be a list of ordered key-value pairs, e.g. (key1, value1, key2, value2, ...) -> { key1: value1, key2: value2, ... }',
		category = 'objects',
		--[[/minify-delete]]
	},
	array = {
		valid = { { 'object' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'obj' },
		description =
		'Convert an object into an array. The array will be a list of key-value pairs, e.g. {key1: value1, key2: value2, ...} -> (key1, value1, key2, value2, ...).',
		category = 'objects',
		--[[/minify-delete]]
	},
	keys = {
		valid = { { 'object' } },
		out = 'array[string]',
		--[[minify-delete]]
		params = { 'obj' },
		description = 'List an object\'s keys.',
		category = 'objects',
		--[[/minify-delete]]
	},
	values = {
		valid = { { 'object' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'obj' },
		description = 'List an object\'s values.',
		category = 'objects',
		--[[/minify-delete]]
	},
	pairs = {
		valid = { { 'object' }, { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'data' },
		description =
		'Get a list of key-value pairs for an object or array. The output will be a list of 2-element lists, e.g. {key1: value1, key2: value2, ...} -> ((key1, value1), (key2, value2), ...).',
		category = 'objects',
		--[[/minify-delete]]
	},
	interleave = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list1', 'list2' },
		description = 'Interleave the values of two arrays. E.g. (1, 2, 3) and (4, 5, 6) -> (1, 4, 2, 5, 3, 6).',
		category = 'arrays',
		--[[/minify-delete]]
	},
	unique = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list' },
		description =
		'Remove duplicate values from an array. This function is most useful for creating a set, which can then be passed to other set operations.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	union = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description =
		'Get the union of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	intersection = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description =
		'Get the intersection of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	difference = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description =
		'Get the difference of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	symmetric_difference = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description =
		'Get the symmetric difference of two sets. Note that if either set contains duplicate elements, they may or may not be preserved.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	is_disjoint = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Check if two sets are disjoint. Returns true if they have no elements in common.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	is_subset = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description =
		'Check if the first set is a subset of the second. Returns true if all elements of the first set are in the second set.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	is_superset = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description =
		'Check if the first set is a superset of the second. Returns true if all elements of the second set are in the first set.',
		category = 'arrays:sets',
		--[[/minify-delete]]
	},
	flatten = {
		valid = { { 'array', 'number' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'depth' },
		description =
		'Flatten an array of any dimension into a 1D array. E.g. ((1, 2), (3, (4, 5))) -> (1, 2, 3, 4, 5). Optionally specify a depth to only flatten that many levels.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	sinh = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the hyperbolic sine of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	cosh = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the hyperbolic cosine of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	tanh = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the hyperbolic tangent of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	sign = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Get the signedness of a number. returns -1 if negative, 0 if zero, 1 if positive.',
		category = 'math',
		--[[/minify-delete]]
	},
	ascii = {
		valid = { { 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'character' },
		description =
		'Convert a character to its ASCII value. Only the first character is considered, all others are ignored.',
		category = 'characters',
		--[[/minify-delete]]
	},
	char = {
		valid = { { 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'ascii_code' },
		description =
		'Convert an ASCII number to a character. If outside of the range 0-255, an empty string is returned. Non-integers are rounded down.',
		category = 'characters',
		--[[/minify-delete]]
	},
	beginswith = {
		valid = { { 'string' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'search', 'substring' },
		description = 'Check if the search string begins with the given substring.',
		category = 'strings',
		--[[/minify-delete]]
	},
	endswith = {
		valid = { { 'string' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'search', 'substring' },
		description = 'Check if the search string ends with the given substring.',
		category = 'strings',
		--[[/minify-delete]]
	},
	to_base = {
		valid = { { 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'number', 'base', 'pad_width' },
		description =
		'Convert a number to a numeric string of any base from 2 to 36. Optionally pad the string with leading zeros to a given width. E.g. 42 in base 16 with padding of 4 would be "002A".',
		category = 'strings',
		--[[/minify-delete]]
	},
	time = {
		valid = { { 'array[number]|number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'timestamp' },
		description =
		'Convert a number or array representation of a time (timestamp OR [hour, min, sec, milli]) into an ISO compliant time string.',
		category = 'time',
		--[[/minify-delete]]
	},
	date = {
		valid = { { 'array[number]' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'date_array' },
		description = 'Convert an array representation of a date (day, month, year) into an ISO compliant date string.',
		category = 'time',
		--[[/minify-delete]]
	},
	random_elements = {
		valid = { { 'array', 'number' } },
		out = 'any',
		--[[minify-delete]]
		params = { 'list', 'count' },
		description =
		'Select non-repeating random elements from a list. If count is greater than the number of elements in the list, all elements will be returned in random order.',
		category = 'randomization',
		--[[/minify-delete]]
	},
	shuffle = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list' },
		description =
		'Shuffle an array\'s elements into a random order. This is identical to calling random_elements with count set to the length of the array.',
		category = 'randomization',
		--[[/minify-delete]]
	},
	match = {
		valid = { { 'string' } },
		out = 'string?',
		--[[minify-delete]]
		params = { 'text', 'pattern' },
		description = 'Get the first substring that matches the given pattern. If no match is found, null is returned.',
		category = 'strings',
		--[[/minify-delete]]
	},
	splice = {
		valid = { { 'array', 'number', 'number', 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'start', 'end', 'replacement' },
		description = 'Remove or replace elements from an array.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	uuid = {
		value = {},
		out = 'string',
		--[[minify-delete]]
		description =
		'Generate a universally unique identifier (UUID). See https://en.wikipedia.org/wiki/Universally_unique_identifier for more information.',
		category = 'miscellaneous',
		--[[/minify-delete]]
	},
	glob = {
		valid = { { 'string', 'any' } },
		out = 'array[string]',
		--[[minify-delete]]
		params = { 'glob_pattern', '...' },
		description =
		'Convert a glob pattern into a list of strings. E.g. `glob("a?*", "b", "c")` or `glob("a?*", ("b", "c"))` -> ("a?b", "a?c").',
		category = 'strings',
		--[[/minify-delete]]
	},
	xml_encode = {
		valid = { { 'array[object]' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Serialize data to an XML string.',
		category = 'encoding',
		--[[/minify-delete]]
	},
	xml_decode = {
		valid = { { 'string' } },
		out = 'array[object]',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Deserialize data from an XML string.',
		category = 'encoding',
		--[[/minify-delete]]
	},
	log = {
		valid = { { 'number', 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'base', 'value' },
		description =
		'Calculate the logarithm of a number with a given base, or the natural logarithm if no base is provided.',
		category = 'math',
		--[[/minify-delete]]
	},
	normalize = {
		valid = { { 'array[number]' } },
		out = 'array[number]',
		--[[minify-delete]]
		params = { 'vector' },
		description = 'Normalize a vector to length 1. E.g. (3, 4) -> (0.6, 0.8).',
		category = 'arrays:vectors'
		--[[/minify-delete]]
	},
	random_weighted = {
		valid = { { 'array[any]', 'array[number]' } },
		out = 'any',
		--[[minify-delete]]
		params = { 'list', 'weights' },
		description =
		'Select a random element from a list according to a weight distribution. Weights will be normalized to sum to 1, so weights like (1, 2, 3) are fine and will be treated as (0.166, 0.333, 0.5); that is, the third element will be three times more likely to be selected than the first element.',
		category = 'randomization',
		--[[/minify-delete]]
	},
	trim = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'chars' },
		description =
		'Remove any of the given characters from the beginning and end of a string. If chars is not provided, any whitespace will be removed.',
		category = 'strings',
		--[[/minify-delete]]
	},
	modf = {
		valid = { { 'number' } },
		out = 'array[number]',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Split a number into its integer and fractional parts. E.g. 3.14 -> (3, 0.14).',
		category = 'math',
		--[[/minify-delete]]
	},
	all = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'list' },
		description =
		'Check if all elements in an array are truthy. This is identical to calling `reduce(..., and)`.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	any = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Check if any element in an array is truthy. This is identical to calling `reduce(..., or)`.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	cot = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the cotangent of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	acot = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the arccotangent of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	sec = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the secant of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	asec = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the arcsecant of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	csc = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the cosecant of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	acsc = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Calculate the arccosecant of a number.',
		category = 'math',
		--[[/minify-delete]]
	},
	from_base = {
		valid = { { 'string', 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'text', 'base' },
		description =
		'Convert a numeric string of any base from 2 to 36 into a number. E.g. "2A" in base 16 would be 42. If the string contains invalid characters, 0 is returned.',
		category = 'strings',
		--[[/minify-delete]]
	},
	chunk = {
		valid = { { 'array', 'number' } },
		out = 'array[array]',
		--[[minify-delete]]
		params = { 'list', 'chunk_size' },
		description =
		'Split an array into chunks of a given size. The last chunk may be smaller than the given size if the array length is not a multiple of the chunk size.',
		category = 'arrays',
		--[[/minify-delete]]
	},
	timestamp = {
		valid = { { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'time_array' },
		description = 'Convert an (hour, min, sec, milli) array into a "seconds since midnight" timestamp.',
		category = 'time',
		--[[/minify-delete]]
	},
	--[[minify-delete]]
	toepoch = {
		valid = { { 'object' } },
		out = 'number',
		params = { 'datetime' },
		description =
		'Convert a datetime object to epoch time (seconds since Jan 1, 1970). The datetime object is expected to have the following form: { date: (day, month, year), time: (hour, min, sec) }.',
		category = 'time',
		plasma = false,
	},
	fromepoch = {
		valid = { { 'number' } },
		out = 'object',
		params = { 'timestamp' },
		description =
		'Convert epoch time (seconds since Jan 1, 1970) to a datetime object. The datetime object will have the following form: { date: (day, month, year), time: (hour, min, sec) }.',
		category = 'time',
		plasma = false,
	},
	epochnow = {
		value = {},
		out = 'number',
		description =
		'Get the current epoch time (seconds since Jan 1, 1970).',
		category = 'time',
		plasma = false,
	},
	file_glob = {
		valid = { { 'string' } },
		out = 'array[string]',
		params = { 'glob_pattern' },
		description =
		'List all files that match a glob pattern. E.g. `file_glob("*.txt")` -> ("file1.txt", "file2.txt"), depending on the files in your current directory.',
		category = 'files',
		plasma = false,
	},
	file_exists = {
		valid = { { 'string' } },
		out = 'boolean',
		params = { 'file_path' },
		description = 'Check if a file exists at the given path.',
		category = 'files',
		plasma = false,
	},
	file_size = {
		valid = { { 'string' } },
		out = 'number',
		params = { 'file_path' },
		description = 'Get the size of a file in bytes. If the file does not exist, 0 is returned.',
		category = 'files',
		plasma = false,
	},
	file_read = {
		valid = { { 'string' } },
		out = 'string?',
		params = { 'file_path' },
		description =
		'Read the entire contents of a file as a string. If the file does not exist or cannot be read, null is returned.',
		category = 'files',
		plasma = false,
	},
	file_write = {
		valid = { { 'string' } },
		out = 'boolean',
		params = { 'file_path', 'data' },
		description =
		'Write a string to a file, overwriting it if it already exists. Returns true on success, or false if the file could not be written.',
		category = 'files',
		plasma = false,
	},
	file_append = {
		valid = { { 'string' } },
		out = 'boolean',
		params = { 'file_path', 'data' },
		description =
		'Append a string to the end of a file, creating it if it does not exist. Returns true on success, or false if the file could not be written.',
		category = 'files',
		plasma = false,
	},
	file_delete = {
		valid = { { 'string' } },
		out = 'boolean',
		params = { 'file_path' },
		description = 'Delete a file. Returns true on success, or false if the file could not be deleted.',
		category = 'files',
		plasma = false,
	},
	dir_create = {
		valid = { { 'string', 'boolean' } },
		out = 'boolean',
		params = { 'dir_path', 'create_parents' },
		description =
		'Create a directory. Returns true on success, or false if the directory could not be created. If create_parents is true, any missing parent directories will also be created.',
		category = 'files',
		plasma = false,
	},
	dir_list = {
		valid = { { 'string' } },
		out = 'array[string]',
		params = { 'dir_path' },
		description =
		'List all files and directories in the given directory. If the directory does not exist, an empty array is returned.',
		category = 'files',
		plasma = false,
	},
	dir_delete = {
		valid = { { 'string', 'boolean' } },
		out = 'boolean',
		params = { 'dir_path', 'recursive' },
		description =
		'Delete a directory. Returns true on success, or false if the directory could not be deleted. If recursive is true, all files and subdirectories will also be deleted.',
		category = 'files',
		plasma = false,
	},
	file_type = {
		valid = { { 'string' } },
		out = 'string?',
		params = { 'file_path' },
		description =
		'Get the type of a file. Possible return values are "file", "directory", or "other". If the file does not exist, null is returned.',
		category = 'files',
		plasma = false,
	},
	file_stat = {
		valid = { { 'string' } },
		out = 'object?',
		params = { 'file_path' },
		description =
		'Get information about a filesystem object. If the file does not exist, null is returned.',
		category = 'files',
		plasma = false,
	},
	file_copy = {
		valid = { { 'string', 'string', 'boolean' } },
		out = 'boolean',
		params = { 'source_path', 'dest_path', 'overwrite' },
		description =
		'Copy a file from source_path to dest_path. If overwrite is true, any existing file at dest_path will be overwritten. Returns true on success, or false if the file could not be copied.',
		category = 'files',
		plasma = false,
	},
	file_move = {
		valid = { { 'string', 'string', 'boolean' } },
		out = 'boolean',
		params = { 'source_path', 'dest_path', 'overwrite' },
		description =
		'Move a file from source_path to dest_path. If overwrite is true, any existing file at dest_path will be overwritten. Returns true on success, or false if the file could not be moved.',
		category = 'files',
		plasma = false,
	},
	--[[/minify-delete]]

	[TOK.add] = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
	},
	[TOK.multiply] = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
	},
	[TOK.exponent] = {
		valid = { { 'number' } },
		out = 'number',
	},
	[TOK.boolean] = {
		out = 'boolean',
	},
	[TOK.array_concat] = {
		out = 'array',
	},
	[TOK.array_slice] = {
		valid = { { 'number', 'number' } },
		out = 'array[number]',
	},
	[TOK.comparison] = {
		out = 'boolean',
	},
	[TOK.negate] = {
		valid = { { 'number' }, { 'array' } },
		out = 'number',
	},
	[TOK.concat] = {
		out = 'string',
	},
	[TOK.length] = {
		out = 'number',
	},
	[TOK.string_open] = {
		out = 'string',
	},
	[TOK.list_comp] = {
		out = 'array',
	},
}

--Convert all type signatures in the above from strings to type signature objects.
for _, item in pairs(TYPESIG) do
	if not item.valid then item.valid = { { 'any' } } end

	for option = 1, #item.valid do
		for param = 1, #item.valid[option] do
			---@diagnostic disable-next-line
			item.valid[option][param] = SIGNATURE(item.valid[option][param])
		end
	end

	--A numeric output of N means that the output will be the same type as the Nth parameter.
	if type(item.out) == 'string' then
		---@diagnostic disable-next-line
		item.out = SIGNATURE(item.out)
	end
end
