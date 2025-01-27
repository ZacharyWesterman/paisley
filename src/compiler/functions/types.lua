--Specify the type signature for every function and operator
--Also specify help info if not the Plasma build.
TYPESIG = {
	random_int = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'min', 'max' },
		description = 'Generate a random integer',
		--[[/minify-delete]]
	},
	random_float = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'min', 'max' },
		description = 'Generate a random real number',
		--[[/minify-delete]]
	},
	random_element = {
		valid = { { 'array' } },
		out = 'any',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Select a random element from a list',
		--[[/minify-delete]]
	},
	word_diff = {
		valid = { { 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'word1', 'word2' },
		description = 'Get the levenshtein difference between two strings',
		--[[/minify-delete]]
	},
	dist = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'point1', 'point2' },
		description = 'Get the euclidean distance between numbers or vectors of the same dimension',
		--[[/minify-delete]]
	},
	sin = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Sine',
		--[[/minify-delete]]
	},
	cos = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Cosine',
		--[[/minify-delete]]
	},
	tan = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Tangent',
		--[[/minify-delete]]
	},
	asin = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Arcsine',
		--[[/minify-delete]]
	},
	acos = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Arccosine',
		--[[/minify-delete]]
	},
	atan = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Arctangent',
		--[[/minify-delete]]
	},
	atan2 = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x', 'y' },
		description = '2-argument arctangent',
		--[[/minify-delete]]
	},
	sqrt = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Square root',
		--[[/minify-delete]]
	},
	bytes = {
		valid = { { 'number' } },
		out = 'array[number]',
		--[[minify-delete]]
		params = { 'value' },
		description = 'Split a number into bytes',
		--[[/minify-delete]]
	},
	frombytes = {
		valid = { { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'bytes' },
		description = 'Convert a list of bytes into a number',
		--[[/minify-delete]]
	},
	sum = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Sum N values',
		--[[/minify-delete]]
	},
	mult = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Multiply N values',
		--[[/minify-delete]]
	},
	min = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Find the minimum of N values',
		--[[/minify-delete]]
	},
	max = {
		valid = { { 'number' }, { 'array[number]' } },
		out = 'number',
		--[[minify-delete]]
		description = 'Find the maximum of N values',
		--[[/minify-delete]]
	},
	clamp = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'value', 'min', 'max' },
		description = 'Keep a value inside the given range',
		--[[/minify-delete]]
	},
	smoothstep = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'value', 'min', 'max' },
		description = 'Smoothly transition from 0 to 1 in a given range',
		--[[/minify-delete]]
	},
	lerp = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'ratio', 'start', 'end' },
		description = 'Linearly interpolate between two numbers',
		--[[/minify-delete]]
	},
	split = {
		valid = { { 'string', 'string' } },
		out = 'array[string]',
		--[[minify-delete]]
		params = { 'text', 'delim' },
		description = 'Split a string into an array based on a delimiter',
		--[[/minify-delete]]
	},
	join = {
		valid = { { 'array', 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'list', 'delim' },
		description = 'Merge an array into a string with a delimiter between elements',
		--[[/minify-delete]]
	},
	count = {
		valid = { { 'array', 'any' }, { 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'iter', 'value' },
		description = 'Count the number of occurrences of a value in an array or string',
		--[[/minify-delete]]
	},
	index = {
		valid = { { 'array', 'any' }, { 'string', 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'iter', 'value' },
		description = 'Find the index of the nth occurrence of a value in an array or string',
		--[[/minify-delete]]
	},
	find = {
		valid = { { 'array', 'any', 'number' }, { 'string', 'string', 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'iter', 'value', 'occurrence' },
		description = 'Find the index of the first occurrence of a value in an array or string',
		--[[/minify-delete]]
	},
	type = {
		out = 'string',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Get the data type of a value',
		--[[/minify-delete]]
	},
	bool = {
		out = 'boolean',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Convert a value to a boolean',
		--[[/minify-delete]]
	},
	num = {
		out = 'number',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Convert a value to a number',
		--[[/minify-delete]]
	},
	int = {
		out = 'number',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Convert a value to an integer',
		--[[/minify-delete]]
	},
	str = {
		out = 'string',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Convert a value to a string',
		--[[/minify-delete]]
	},
	floor = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Round down',
		--[[/minify-delete]]
	},
	ceil = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Round up',
		--[[/minify-delete]]
	},
	round = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Round to the nearest integer',
		--[[/minify-delete]]
	},
	abs = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Get the absolute value',
		--[[/minify-delete]]
	},
	append = {
		valid = { { 'array', 'any' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'value' },
		description = 'Append a value to an array',
		--[[/minify-delete]]
	},
	lower = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert a string to lowercase',
		--[[/minify-delete]]
	},
	upper = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert a string to uppercase',
		--[[/minify-delete]]
	},
	camel = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Capitalize the first letter of every word',
		--[[/minify-delete]]
	},
	replace = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'search', 'replace' },
		description = 'Replace all occurrences of a substring',
		--[[/minify-delete]]
	},
	json_encode = {
		valid = { { 'any', 'boolean' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Serialize data to a JSON string',
		--[[/minify-delete]]
	},
	json_decode = {
		valid = { { 'string' } },
		out = 'any',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Deserialize data from a JSON string',
		--[[/minify-delete]]
	},
	json_valid = {
		out = 'boolean',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Check if a JSON string is formatted correctly',
		--[[/minify-delete]]
	},
	b64_encode = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert a string to base64',
		--[[/minify-delete]]
	},
	b64_decode = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Convert base64 text to a string',
		--[[/minify-delete]]
	},
	lpad = {
		valid = { { 'string', 'string', 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'pad_char', 'width' },
		description = 'Left-pad a string with a given character',
		--[[/minify-delete]]
	},
	rpad = {
		valid = { { 'string', 'string', 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'pad_char', 'width' },
		description = 'Right-pad a string with a given character',
		--[[/minify-delete]]
	},
	hex = {
		valid = { { 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'value' },
		description = 'Convert a number to a hexadecimal string',
		--[[/minify-delete]]
	},
	filter = {
		valid = { { 'string', 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text', 'valid_chars' },
		description = 'Remove all characters that do not match the given pattern',
		--[[/minify-delete]]
	},
	matches = {
		valid = { { 'string', 'string' } },
		out = 'array[string]',
		--[[minify-delete]]
		params = { 'text', 'pattern' },
		description = 'Get all substrings that match the given pattern',
		--[[/minify-delete]]
	},
	clocktime = {
		valid = { { 'number' } },
		out = 'array[number]',
		--[[minify-delete]]
		params = { 'timestamp' },
		description = 'Convert a "seconds since midnight" timestamp into (hour, min, sec, milli)',
		--[[/minify-delete]]
	},
	reduce = {
		valid = { { 'array', 'any' } },
		--[[minify-delete]]
		params = { 'list', 'op' },
		description = 'Reduce an array to a single element',
		--[[/minify-delete]]
	},
	reverse = {
		valid = { { 'array' }, { 'string' } },
		out = 1, --output type is the same as that of the first parameter
		--[[minify-delete]]
		params = { 'iter' },
		description = 'Reverse an array or a string',
		--[[/minify-delete]]
	},
	sort = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Sort an array in ascending order',
		--[[/minify-delete]]
	},
	merge = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list1', 'list2' },
		description = 'Join two arrays together',
		--[[/minify-delete]]
	},
	update = {
		valid = { { 'array', 'number', 'any' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'index', 'new_value' },
		description = 'Replace an element in an array',
		--[[/minify-delete]]
	},
	insert = {
		valid = { { 'array', 'number', 'any' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'before_index', 'value' },
		description = 'Insert an element in an array',
		--[[/minify-delete]]
	},
	delete = {
		valid = { { 'array', 'number' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list', 'index' },
		description = 'Delete an element from an array',
		--[[/minify-delete]]
	},
	hash = {
		valid = { { 'string' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'text' },
		description = 'Generate the SHA256 hash of a string',
		--[[/minify-delete]]
	},
	object = {
		valid = { { 'array' } },
		out = 'object',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Convert an array into an object',
		--[[/minify-delete]]
	},
	array = {
		valid = { { 'object' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'obj' },
		description = 'Convert an object into an array',
		--[[/minify-delete]]
	},
	keys = {
		valid = { { 'object' } },
		out = 'array[string]',
		--[[minify-delete]]
		params = { 'obj' },
		description = 'List an object\'s keys',
		--[[/minify-delete]]
	},
	values = {
		valid = { { 'object' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'obj' },
		description = 'List an object\'s values',
		--[[/minify-delete]]
	},
	pairs = {
		valid = { { 'object' }, { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'data' },
		description = 'Get a list of key-value pairs for an object or array',
		--[[/minify-delete]]
	},
	interleave = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list1', 'list2' },
		description = 'Interleave the values of two arrays',
		--[[/minify-delete]]
	},
	unique = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Make sure an array has no repeated elements',
		--[[/minify-delete]]
	},
	union = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Get the union of two sets',
		--[[/minify-delete]]
	},
	intersection = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Get the intersection of two sets',
		--[[/minify-delete]]
	},
	difference = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Get the difference of two sets',
		--[[/minify-delete]]
	},
	symmetric_difference = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Get the symmetric difference of two sets',
		--[[/minify-delete]]
	},
	is_disjoint = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Check if two sets are disjoint',
		--[[/minify-delete]]
	},
	is_subset = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Check if the first set is a subset of the second',
		--[[/minify-delete]]
	},
	is_superset = {
		valid = { { 'array' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'set1', 'set2' },
		description = 'Check if the first set is a superset of the second',
		--[[/minify-delete]]
	},
	flatten = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Flatten an array of any dimension into a 1D array',
		--[[/minify-delete]]
	},
	sinh = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Hyperbolic sine',
		--[[/minify-delete]]
	},
	cosh = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Hyperbolic cosine',
		--[[/minify-delete]]
	},
	tanh = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Hyperbolic tangent',
		--[[/minify-delete]]
	},
	sign = {
		valid = { { 'number' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'x' },
		description = 'Sign of a number: -1 if negative, 0 if zero, 1 if positive',
		--[[/minify-delete]]
	},
	ascii = {
		valid = { { 'string' } },
		out = 'number',
		--[[minify-delete]]
		params = { 'character' },
		description =
		'Convert a character to its ASCII value. Only the first character is considered, all others are ignored.',
		--[[/minify-delete]]
	},
	char = {
		valid = { { 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'ascii_code' },
		description =
		'Convert an ASCII number to a character. If outside of the range 0-255, an empty string is returned. Non-integers are rounded down.',
		--[[/minify-delete]]
	},
	beginswith = {
		valid = { { 'string' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'search', 'substring' },
		description = 'Check if the search string begins with the given substring.',
		--[[/minify-delete]]
	},
	endswith = {
		valid = { { 'string' } },
		out = 'boolean',
		--[[minify-delete]]
		params = { 'search', 'substring' },
		description = 'Check if the search string ends with the given substring.',
		--[[/minify-delete]]
	},
	numeric_string = {
		valid = { { 'number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'number', 'base', 'pad_width' },
		description = 'Convert a number to a numeric string of any base from 2 to 36.',
		--[[/minify-delete]]
	},
	time = {
		valid = { { 'array[number]|number' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'timestamp' },
		description =
		'Convert a number or array representation of a time (timestamp OR [hour, min, sec, milli]) into an ISO compliant time string.',
		--[[/minify-delete]]
	},
	date = {
		valid = { { 'array[number]' } },
		out = 'string',
		--[[minify-delete]]
		params = { 'date_array' },
		description = 'Convert an array representation of a date (day, month, year) into an ISO compliant date string.',
		--[[/minify-delete]]
	},
	random_elements = {
		valid = { { 'array', 'number' } },
		out = 'any',
		--[[minify-delete]]
		params = { 'list', 'count' },
		description = 'Select (non-repeating) random elements from a list',
		--[[/minify-delete]]
	},
	shuffle = {
		valid = { { 'array' } },
		out = 'array',
		--[[minify-delete]]
		params = { 'list' },
		description = 'Shuffle an array\'s elements into a random order',
		--[[/minify-delete]]
	},

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
