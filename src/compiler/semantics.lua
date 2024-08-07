BUILTIN_FUNCS = {
	random_int = 2,
	random_float = 2,
	word_diff = 2,
	dist = 2,
	sin = 1,
	cos = 1,
	tan = 1,
	asin = 1,
	acos = 1,
	atan = 1,
	atan2 = 2,
	sqrt = 1,
	bytes = 2,
	sum = -1, --at least 1 param
	mult = -1,
	min = -1,
	max = -1,
	clamp = 3, --clamp(a, b, x) = min(b, max(a, x))
	smoothstep = 3,
	lerp = 3, --lerp(a, b, x) = a + x*(b - a) : 0 <= x <= 1
	split = 2,
	join = 2,
	type = 1,
	bool = 1,
	str = 1,
	num = 1,
	int = 1,
	floor = 1,
	ceil = 1,
	round = 1,
	abs = 1,
	append = 2,
	index = 2,
	lower = 1,
	upper = 1,
	camel = 1,
	replace = 3,
	json_encode = -2, --value of -N means that the function must have at least 1, and up to N, params.
	json_decode = 1,
	json_valid = 1,
	b64_encode = 1,
	b64_decode = 1,
	lpad = 3,
	rpad = 3,
	hex = 1,
	filter = 2,
	matches = 2,
	clocktime = 1,
	reverse = 1,
	sort = 1,
	reduce = 2,
	frombytes = 1,
	merge = 2,
	update = 3,
	insert = 3,
	delete = 2,
	random_element = 1,
	hash = 1,
	object = 1,
	array = 1,
	keys = 1,
	values = 1,
	pairs = 1,
	interleave = 2,
	unique = 1,
	union = 2,
	intersection = 2,
	difference = 2,
	symmetric_difference = 2,
	is_disjoint = 2,
	is_subset = 2,
	is_superset = 2,
	count = 2,
	find = 3,
	flatten = 1,
	sinh = 1,
	cosh = 1,
	tanh = 1,
	sign = 1,
	ascii = 1,
	char = 1,
	beginswith = 2,
	endswith = 2,
}

TYPESIG = {
	random_int = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'min', 'max'},
		description = 'Generate a random integer',
		--[[/minify-delete]]
	},
	random_float = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'min', 'max'},
		description = 'Generate a random real number',
		--[[/minify-delete]]
	},
	random_element = {
		valid = {{'array'}},
		out = 'any',
		--[[minify-delete]]
		params = {'list'},
		description = 'Select a random element from a list',
		--[[/minify-delete]]
	},
	word_diff = {
		valid = {{'string'}},
		out = 'number',
		--[[minify-delete]]
		params = {'word1', 'word2'},
		description = 'Get the levenshtein difference between two strings',
		--[[/minify-delete]]
	},
	dist = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
		--[[minify-delete]]
		params = {'point1', 'point2'},
		description = 'Get the euclidean distance between numbers or vectors of the same dimension',
		--[[/minify-delete]]
	},
	sin = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Sine',
		--[[/minify-delete]]
	},
	cos = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Cosine',
		--[[/minify-delete]]
	},
	tan = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Tangent',
		--[[/minify-delete]]
	},
	asin = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Arcsine',
		--[[/minify-delete]]
	},
	acos = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Arccosine',
		--[[/minify-delete]]
	},
	atan = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Arctangent',
		--[[/minify-delete]]
	},
	atan2 = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x', 'y'},
		description = '2-argument arctangent',
		--[[/minify-delete]]
	},
	sqrt = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Square root',
		--[[/minify-delete]]
	},
	bytes = {
		valid = {{'number'}},
		out = 'array[number]',
		--[[minify-delete]]
		params = {'value'},
		description = 'Split a number into bytes',
		--[[/minify-delete]]
	},
	frombytes = {
		valid = {{'array[number]'}},
		out = 'number',
		--[[minify-delete]]
		params = {'bytes'},
		description = 'Convert a list of bytes into a number',
		--[[/minify-delete]]
	},
	sum = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
		--[[minify-delete]]
		description = 'Sum N values',
		--[[/minify-delete]]
	},
	mult = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
		--[[minify-delete]]
		description = 'Multiply N values',
		--[[/minify-delete]]
	},
	min = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
		--[[minify-delete]]
		description = 'Find the minimum of N values',
		--[[/minify-delete]]
	},
	max = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
		--[[minify-delete]]
		description = 'Find the maximum of N values',
		--[[/minify-delete]]
	},
	clamp = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'value', 'min', 'max'},
		description = 'Keep a value inside the given range',
		--[[/minify-delete]]
	},
	smoothstep = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'value', 'min', 'max'},
		description = 'Smoothly transition from 0 to 1 in a given range',
		--[[/minify-delete]]
	},
	lerp = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'ratio', 'start', 'end'},
		description = 'Linearly interpolate between two numbers',
		--[[/minify-delete]]
	},
	split = {
		valid = {{'string', 'string'}},
		out = 'array[string]',
		--[[minify-delete]]
		params = {'text', 'delim'},
		description = 'Split a string into an array based on a delimiter',
		--[[/minify-delete]]
	},
	join = {
		valid = {{'array', 'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'list', 'delim'},
		description = 'Merge an array into a string with a delimiter between elements',
		--[[/minify-delete]]
	},
	count = {
		valid = {{'array','any'}, {'string'}},
		out = 'number',
		--[[minify-delete]]
		params = {'iter', 'value'},
		description = 'Count the number of occurrences of a value in an array or string',
		--[[/minify-delete]]
	},
	index = {
		valid = {{'array', 'array[number]'}, {'array', 'number'}, {'string', 'array[number]'}, {'string', 'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'iter', 'value'},
		description = 'Find the index of the nth occurrence of a value in an array or string',
		--[[/minify-delete]]
	},
	find = {
		valid = {{'array','any','number'},{'string','string','number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'iter', 'value', 'occurrence'},
		description = 'Find the index of the first occurrence of a value in an array or string',
		--[[/minify-delete]]
	},
	type = {
		out = 'string',
		--[[minify-delete]]
		params = {'data'},
		description = 'Get the data type of a value',
		--[[/minify-delete]]
	},
	bool = {
		out = 'boolean',
		--[[minify-delete]]
		params = {'data'},
		description = 'Convert a value to a boolean',
		--[[/minify-delete]]
	},
	num = {
		out = 'number',
		--[[minify-delete]]
		params = {'data'},
		description = 'Convert a value to a number',
		--[[/minify-delete]]
	},
	int = {
		out = 'number',
		--[[minify-delete]]
		params = {'data'},
		description = 'Convert a value to an integer',
		--[[/minify-delete]]
	},
	str = {
		out = 'string',
		--[[minify-delete]]
		params = {'data'},
		description = 'Convert a value to a string',
		--[[/minify-delete]]
	},
	floor = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Round down',
		--[[/minify-delete]]
	},
	ceil = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Round up',
		--[[/minify-delete]]
	},
	round = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Round to the nearest integer',
		--[[/minify-delete]]
	},
	abs = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Get the absolute value',
		--[[/minify-delete]]
	},
	append = {
		valid = {{'array', 'any'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list', 'value'},
		description = 'Append a value to an array',
		--[[/minify-delete]]
	},
	lower = {
		valid = {{'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text'},
		description = 'Convert a string to lowercase',
		--[[/minify-delete]]
	},
	upper = {
		valid = {{'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text'},
		description = 'Convert a string to uppercase',
		--[[/minify-delete]]
	},
	camel = {
		valid = {{'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text'},
		description = 'Capitalize the first letter of every word',
		--[[/minify-delete]]
	},
	replace = {
		valid = {{'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text', 'search', 'replace'},
		description = 'Replace all occurrences of a substring',
		--[[/minify-delete]]
	},
	json_encode = {
		valid = {{'any', 'boolean'}},
		out = 'string',
		--[[minify-delete]]
		params = {'data'},
		description = 'Serialize data to a JSON string',
		--[[/minify-delete]]
	},
	json_decode = {
		valid = {{'string'}},
		out = 'any',
		--[[minify-delete]]
		params = {'text'},
		description = 'Deserialize data from a JSON string',
		--[[/minify-delete]]
	},
	json_valid = {
		out = 'boolean',
		--[[minify-delete]]
		params = {'text'},
		description = 'Check if a JSON string is formatted correctly',
		--[[/minify-delete]]
	},
	b64_encode = {
		valid = {{'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text'},
		description = 'Convert a string to base64',
		--[[/minify-delete]]
	},
	b64_decode = {
		valid = {{'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text'},
		description = 'Convert base64 text to a string',
		--[[/minify-delete]]
	},
	lpad = {
		valid = {{'string', 'string', 'number'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text', 'pad_char', 'width'},
		description = 'Left-pad a string with a given character',
		--[[/minify-delete]]
	},
	rpad = {
		valid = {{'string', 'string', 'number'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text', 'pad_char', 'width'},
		description = 'Right-pad a string with a given character',
		--[[/minify-delete]]
	},
	hex = {
		valid = {{'number'}},
		out = 'string',
		--[[minify-delete]]
		params = {'value'},
		description = 'Convert a number to a hexadecimal string',
		--[[/minify-delete]]
	},
	filter = {
		valid = {{'string', 'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text', 'valid_chars'},
		description = 'Remove all characters that do not match the given pattern',
		--[[/minify-delete]]
	},
	matches = {
		valid = {{'string', 'string'}},
		out = 'array[string]',
		--[[minify-delete]]
		params = {'text', 'pattern'},
		description = 'Get all substrings that match the given pattern',
		--[[/minify-delete]]
	},
	clocktime = {
		valid = {{'number'}},
		out = 'array[number]',
		--[[minify-delete]]
		params = {'timestamp'},
		description = 'Convert a "seconds since midnight" timestamp into (hour, min, sec, milli)',
		--[[/minify-delete]]
	},
	reduce = {
		valid = {{'array', 'any'}},
		--[[minify-delete]]
		params = {'list', 'op'},
		description = 'Reduce an array to a single element',
		--[[/minify-delete]]
	},
	reverse = {
		valid = {{'array'}, {'string'}},
		out = 1, --output type is the same as that of the first parameter
		--[[minify-delete]]
		params = {'iter'},
		description = 'Reverse an array or a string',
		--[[/minify-delete]]
	},
	sort = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list'},
		description = 'Sort an array in ascending order',
		--[[/minify-delete]]
	},
	merge = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list1', 'list2'},
		description = 'Join two arrays together',
		--[[/minify-delete]]
	},
	update = {
		valid = {{'array', 'number', 'any'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list', 'index', 'new_value'},
		description = 'Replace an element in an array',
		--[[/minify-delete]]
	},
	insert = {
		valid = {{'array', 'number', 'any'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list', 'before_index', 'value'},
		description = 'Insert an element in an array',
		--[[/minify-delete]]
	},
	delete = {
		valid = {{'array', 'number'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list', 'index'},
		description = 'Delete an element from an array',
		--[[/minify-delete]]
	},
	hash = {
		valid = {{'string'}},
		out = 'string',
		--[[minify-delete]]
		params = {'text'},
		description = 'Generate the SHA256 hash of a string',
		--[[/minify-delete]]
	},
	object = {
		valid = {{'array'}},
		out = 'object',
		--[[minify-delete]]
		params = {'list'},
		description = 'Convert an array into an object',
		--[[/minify-delete]]
	},
	array = {
		valid = {{'object'}},
		out = 'array',
		--[[minify-delete]]
		params = {'obj'},
		description = 'Convert an object into an array',
		--[[/minify-delete]]
	},
	keys = {
		valid = {{'object'}},
		out = 'array[string]',
		--[[minify-delete]]
		params = {'obj'},
		description = 'List an object\'s keys',
		--[[/minify-delete]]
	},
	values = {
		valid = {{'object'}},
		out = 'array',
		--[[minify-delete]]
		params = {'obj'},
		description = 'List an object\'s values',
		--[[/minify-delete]]
	},
	pairs = {
		valid = {{'object'}, {'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'data'},
		description = 'Get a list of key-value pairs for an object or array',
		--[[/minify-delete]]
	},
	interleave = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list1', 'list2'},
		description = 'Interleave the values of two arrays',
		--[[/minify-delete]]
	},
	unique = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list'},
		description = 'Make sure an array has no repeated elements',
		--[[/minify-delete]]
	},
	union = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'set1', 'set2'},
		description = 'Get the union of two sets',
		--[[/minify-delete]]
	},
	intersection = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'set1', 'set2'},
		description = 'Get the intersection of two sets',
		--[[/minify-delete]]
	},
	difference = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'set1', 'set2'},
		description = 'Get the difference of two sets',
		--[[/minify-delete]]
	},
	symmetric_difference = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'set1', 'set2'},
		description = 'Get the symmetric difference of two sets',
		--[[/minify-delete]]
	},
	is_disjoint = {
		valid = {{'array'}},
		out = 'boolean',
		--[[minify-delete]]
		params = {'set1', 'set2'},
		description = 'Check if two sets are disjoint',
		--[[/minify-delete]]
	},
	is_subset = {
		valid = {{'array'}},
		out = 'boolean',
		--[[minify-delete]]
		params = {'set1', 'set2'},
		description = 'Check if the first set is a subset of the second',
		--[[/minify-delete]]
	},
	is_superset = {
		valid = {{'array'}},
		out = 'boolean',
		--[[minify-delete]]
		params = {'set1', 'set2'},
		description = 'Check if the first set is a superset of the second',
		--[[/minify-delete]]
	},
	flatten = {
		valid = {{'array'}},
		out = 'array',
		--[[minify-delete]]
		params = {'list'},
		description = 'Flatten an array of any dimension into a 1D array',
		--[[/minify-delete]]
	},
	sinh = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Hyperbolic sine',
		--[[/minify-delete]]
	},
	cosh = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Hyperbolic cosine',
		--[[/minify-delete]]
	},
	tanh = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Hyperbolic tangent',
		--[[/minify-delete]]
	},
	sign = {
		valid = {{'number'}},
		out = 'number',
		--[[minify-delete]]
		params = {'x'},
		description = 'Sign of a number: -1 if negative, 0 if zero, 1 if positive',
		--[[/minify-delete]]
	},
	ascii = {
		valid = {{'string'}},
		out = 'number',
		--[[minify-delete]]
		params = {'character'},
		description = 'Convert a character to its ASCII value. Only the first character is considered, all others are ignored.',
		--[[/minify-delete]]
	},
	char = {
		valid = {{'number'}},
		out = 'string',
		--[[minify-delete]]
		params = {'ascii_code'},
		description = 'Convert an ASCII number to a character. If outside of the range 0-255, an empty string is returned. Non-integers are rounded down.',
		--[[/minify-delete]]
	},
	beginswith = {
		valid = {{'string'}},
		out = 'boolean',
		--[[minify-delete]]
		params = {'search', 'substring'},
		description = 'Check if the search string begins with the given substring.',
		--[[/minify-delete]]
	},
	endswith = {
		valid = {{'string'}},
		out = 'boolean',
		--[[minify-delete]]
		params = {'search', 'substring'},
		description = 'Check if the search string ends with the given substring.',
		--[[/minify-delete]]
	},

	[TOK.add] = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	[TOK.multiply] = {
		valid = {{'number'}, {'array[number]'}},
		out = 'number',
	},
	[TOK.exponent] = {
		valid = {{'number'}},
		out = 'number',
	},
	[TOK.boolean] = {
		out = 'boolean',
	},
	[TOK.array_concat] = {
		out = 'array',
	},
	[TOK.array_slice] = {
		valid = {{'number', 'number'}},
		out = 'array[number]',
	},
	[TOK.comparison] = {
		out = 'boolean',
	},
	[TOK.negate] = {
		valid = {{'number'}, {'array'}},
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

--Helper func for generating func_call error messages.
function FUNCSIG(func_name)
	local param_ct = BUILTIN_FUNCS[func_name]
	local params = ''
	if param_ct < 0 then
		params = '...'
	elseif param_ct > 0 then
		local i
		for i = 1, param_ct do
			--[[minify-delete]]
			if TYPESIG[func_name].params and TYPESIG[func_name].params[i] then
				params = params .. TYPESIG[func_name].params[i]
			else
			--[[/minify-delete]]
				params = params .. string.char(96 + i)
			--[[minify-delete]]
			end
			local types = {}
			if TYPESIG[func_name].valid then
				for j, k in ipairs(TYPESIG[func_name].valid) do
					local key = k[(i - 1) % #k + 1]
					if key and std.arrfind(types, key, 1) == 0 then table.insert(types, key) end
				end
			else
				table.insert(types, 'any')
			end
			if func_name == 'reduce' and i == 2 then types[1] = 'operator' end
			params = params .. ': ' .. std.join(types, '|')
			--[[/minify-delete]]
			if i < param_ct then params = params .. ',' end
			--[[minify-delete]]
			if i < param_ct then params = params .. ' ' end
			--[[/minify-delete]]
		end
	end
	return params
end

local file_cache = {}

function SemanticAnalyzer(tokens, root_file)
	--[[minify-delete]] SHOW_MULTIPLE_ERRORS = true --[[/minify-delete]]

	---@param root Token
	---@param token_ids TOK[]
	---@param operation fun(token: Token, file: string?)?
	---@param on_exit fun(token: Token, file: string?)?
	local function recurse(root, token_ids, operation, on_exit, file)
		if file == nil then file = root_file end
		if root.filename then file = root.filename end

		local correct_token = false
		for _, id in ipairs(token_ids) do
			if root.id == id then
				correct_token = true
				break
			end
		end

		if correct_token and operation ~= nil then
			operation(root, file)
		end

		if root.children then
			for _, token in ipairs(root.children) do
				recurse(token, token_ids, operation, on_exit, file)
			end
		end

		if correct_token and on_exit ~= nil then
			on_exit(root, file)
		end
	end

	local root = tokens[1] --At this point, there should only be one token, the root "program" token.

	--Make sure subroutines and file imports are top-level statements
	--[[minify-delete]]
	local found_import = false
	local function check_top_level_stmts()
		found_import = false
		--[[/minify-delete]]

		local tok_level = 0
		recurse(root, {TOK.subroutine, --[[minify-delete]] TOK.import_stmt, --[[/minify-delete]] TOK.if_stmt, TOK.for_stmt, TOK.kv_for_stmt, TOK.while_stmt}, function(token, file)
			--[[minify-delete]]
			if token.id == TOK.import_stmt then
				found_import = true
			end
			--[[/minify-delete]]

			--Enter scope
			if tok_level > 0 then
				if token.id == TOK.subroutine then
					parse_error(token.span, 'Subroutines cannot be defined inside other structures', file)
				--[[minify-delete]]
				elseif token.id == TOK.import_stmt then
					parse_error(token.span, 'Statement `'..token.text..'` cannot be inside other structures', file)
				--[[/minify-delete]]
				end
			end

			if token.text:sub(1,1) == '?' then
				parse_error(token.span, 'Subroutine name cannot begin with `?`', file)
			end

			tok_level = tok_level + 1
		end, function(token, file)
			--Exit scope
			tok_level = tok_level - 1
		end)
	--[[minify-delete]]
	end
	check_top_level_stmts()
	--[[/minify-delete]]

	--Enforce top level stmts and import files.
	--Have to repeatedly do this until all dependencies are accounted for
	--[[minify-delete]]
	local imported_files = {} --Keep track of imported files, make sure there are no circular dependencies
	local function import_file(node)
		local new_asts = {}
		for i = 1, #node.value do
			local filename = node.value[i]
			local fp = io.open(filename, 'r')
			local text = nil
			if fp then text = fp:read('*all') end
			if text == nil then
				parse_error(node.span, 'COMPILER BUG: Imported file "'..filename..'" exists but also doesn\'t exist?', root_file)
				break
			end

			if imported_files[filename] then
				parse_error(node.children[i].span, 'File is already imported in '..imported_files[filename], root_file)
				break
			else
				imported_files[filename] = root_file

				local lexer, tokens = Lexer(text, filename), {}
				for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

				--Parse into AST and add to the list.
				local parser = SyntaxParser(tokens, filename)
				while parser.fold() and not ERRORED do end

				if not ERRORED and #parser.get() > 0 then
					local ast = parser.get()[1]
					table.insert(new_asts, ast)
				end

				if ERRORED then
					parse_error(node.children[i].span, 'Error in included file', root_file)
				end
			end
		end

		if ERRORED then return end

		node.id = TOK.program
		node.children = new_asts
	end

	INFO.root_file = root_file

	while found_import and not ERRORED do
		recurse(root, {TOK.import_stmt}, function(token, file)
			import_file(token)
		end)

		check_top_level_stmts()
	end
	--[[/minify-delete]]

	--Flatten "program" nodes so all statements are on the same level.
	recurse(root, {TOK.program}, nil, function(token, file)
		local kids = {}
		for i = 1, #token.children do
			local child = token.children[i]
			if child.id == TOK.program then
				for k = 1, #child.children do table.insert(kids, child.children[k]) end
			else
				table.insert(kids, child)
			end
		end

		token.children = kids
	end)

	--BREAK and CONTINUE statements are only allowed to have up to a single CONSTANT INTEGER operand
	recurse(root, {TOK.break_stmt, TOK.continue_stmt}, function(token, file)
		if not token.children or #token.children == 0 then
			token.children = {{
				id = TOK.lit_number,
				text = '1',
				value = 1,
				span = token.span,
			}}
			return
		end

		token.children = token.children[1].children
		local val = tonumber(token.children[1].text, 10)
		if #token.children > 1 or val == nil or val < 1 then
			parse_error(token.span, 'Only a constant positive integer is allowed as a parameter for "'..token.text..'"', file)
		end
	end)

	--Make sure "delete" statements only have text params. deleting expressions that resolve to variable names is a recipe for disaster.
	recurse(root, {TOK.delete_stmt}, function(token, file)
		---@type Token[]
		local kids = token.children[1].children
		for i = 1, #kids do
			if kids[i].id ~= TOK.text then
				parse_error(kids[i].span, 'Expected only variable names after "delete" keyword', file)
			end
		end

		token.children = kids
	end)

	--Fold nested array_concat tokens into a single array
	recurse(root, {TOK.array_concat}, nil, function(token, file)
		local kids = {}
		for _, child in ipairs(token.children) do
			if child.id == TOK.array_concat or child.id == TOK.object then
				for __, kid in ipairs(child.children) do
					table.insert(kids, kid)
				end
			else
				table.insert(kids, child)
			end
		end

		local is_object = false
		local is_array = false
		for _, child in ipairs(kids) do
			if child.id ~= TOK.array_concat and child.id ~= TOK.object and not child.errored then
				if child.id == TOK.key_value_pair then
					is_object = true
					child.inside_object = true
					if #child.children == 0 and #kids > 1 then
						parse_error(child.span, 'Missing key and value for object construct', file)
						child.errored = true
					end
				else is_array = true end

				if is_object and is_array then
					parse_error(child.span, 'Ambiguous mixture of object and array constructs. Objects require key-value pairs for every element (e.g. `"key" => value`)', file)
					child.errored = true
					break
				end
			end
		end

		if is_object then
			token.id = TOK.object
			token.type = 'object'
		end
		token.children = kids
	end)

	--Extract key-value pairs into objects
	recurse(root, {TOK.key_value_pair}, nil, function(token, file)
		if not token.inside_object then
			local new_token = {
				id = token.id,
				span = token.span,
				text = token.text,
				children = token.children,
				filename = token.filename,
			}
			token.id = TOK.object
			token.text = '{}'
			token.type = 'object'
			token.children = {new_token}
		end
	end)

	--Make a list of all subroutines, and check that return statements are only in subroutines
	local labels = {}
	local inside_sub = 0
	recurse(root, {TOK.subroutine, TOK.return_stmt}, function(token, file)
		if token.id == TOK.subroutine then
			inside_sub = inside_sub + 1

			local label = token.text
			local prev = labels[label]
			if prev ~= nil then
				-- Don't allow tokens to be redeclared
				parse_error(token.span, 'Redeclaration of subroutine "'..label..'" (previously declared on line '..prev.span.from.line..', col '..prev.span.from.col..')', file)
			end

			if not token.children or #token.children == 0 then
				token.ignore = true
			end

			labels[label] = token
		else
			if inside_sub < 1 then
				parse_error(token.span, 'Return statements can only be inside subroutines', file)
			end
		end
	end, function(token, file)
		if token.id == TOK.subroutine then
			inside_sub = inside_sub - 1
		end
	end)

	--Check subroutine references.
	recurse(root, {TOK.gosub_stmt}, function(token, file)
		token.children = token.children[1].children
	end)

	--Resolve all lambda references
	local lambdas = {}
	local tok_level = 0
	local pop_scope = function(token, file, no_decrement)
		if token.id == TOK.lambda then
			if not lambdas[token.text] then lambdas[token.text] = {} end
			table.insert(lambdas[token.text], {
				level = tok_level,
				node = token.children[1]
			})
		elseif token.id == TOK.lambda_ref then
			if not lambdas[token.text] then
				parse_error(token.span, 'Lambda "'..token.text..'" is not defined in the current scope', file)
			else
				--Lambda is defined, so replace it with the appropriate node
				local lambda_node = lambdas[token.text][#lambdas[token.text]].node
				for _, i in ipairs({'text', 'span', 'id', 'value', 'type'}) do
					token[i] = lambda_node[i]
				end
				token.children = lambda_node.children
			end
		else
			--Make sure lambdas are only referenced in the appropriate scope, never outside the scope they're defined.
			for i in pairs(lambdas) do
				while lambdas[i][#lambdas[i]].level > tok_level do
					table.remove(lambdas[i])
					if #lambdas[i] == 0 then
						lambdas[i] = nil
						break
					end
				end
			end

			if not no_decrement then tok_level = tok_level - 1 end
		end
	end
	recurse(root, {TOK.lambda, TOK.lambda_ref, TOK.if_stmt, TOK.while_stmt, TOK.for_stmt, TOK.kv_for_stmt, TOK.subroutine, TOK.else_stmt, TOK.elif_stmt}, function(token, file)
		if token.id ~= TOK.lambda and token.id ~= TOK.lambda_ref then
			if token.id == TOK.else_stmt or token.id == TOK.elif_stmt then
				pop_scope(token, file, true)
			end
			--Make sure lambdas are only referenced in the appropriate scope, never outside the scope they're defined.
			tok_level = tok_level + 1
		end
	end, pop_scope)

	--Replace lambda definitions with the appropriate node.
	recurse(root, {TOK.lambda}, nil, function(token, file)
		local lambda_node = token.children[1]
		for _, i in ipairs({'text', 'span', 'id', 'value', 'type'}) do
			token[i] = lambda_node[i]
		end
		token.children = lambda_node.children
	end)

	--Check function calls
	recurse(root, {TOK.func_call}, function(token, file)
		--Move all params to be direct children
		if not token.children then
			token.children = {}
		elseif #token.children > 0 then
			local kids = {}
			for i = 1, #token.children do
				local child = token.children[i]
				if token.children[i].id == TOK.array_concat then
					local k
					for k = 1, #token.children[i].children do
						table.insert(kids, token.children[i].children[k])
					end
				else
					table.insert(kids, token.children[i])
				end
			end

			token.children = kids
		end

		local func = BUILTIN_FUNCS[token.text]

		--Function doesn't exist
		if func == nil then
			local msg = 'Unknown function "'..token.text..'"'
			local guess = closest_word(token.text:lower(), BUILTIN_FUNCS, 4)

			if guess ~= nil then
				msg = msg .. ' (did you mean "'..guess..'('..FUNCSIG(guess)..')"?)'
			end
			parse_error(token.span, msg, file)
			return
		end

		--Check if function has the right number of params
		local param_ct = #token.children

		if func ~= param_ct then
			local plural = ''
			if func ~= 1 then plural = 's' end
			local verb = 'was'
			if param_ct ~= 1 then verb = 'were' end

			if func < 0 then
				--"-1" means any non-zero num of params, any other negative (-N) means "min 1, max N"

				if func == -1 then
					if param_ct == 0 then
						parse_error(token.span, 'Function "'..token.text..'('..FUNCSIG(token.text)..')" expects at least 1 parameter, but '..param_ct..' '..verb..' given', file)
					end
				elseif param_ct > -func or param_ct < 1 then
					local plural = ''
					if func < -1 then plural = 's' end
					parse_error(token.span, 'Function "'..token.text..'('..FUNCSIG(token.text)..')" expects 1 to '..(-func)..' parameter'..plural..', but '..param_ct..' '..verb..' given', file)
				end
			else
				parse_error(token.span, 'Function "'..token.text..'('..FUNCSIG(token.text)..')" expects '..func..' parameter'..plural..', but '..param_ct..' '..verb..' given', file)
			end
		end

		--For reduce() function, make sure that its second parameter is an operator!
		if token.text == 'reduce' then
			local correct = false
			for i, k in pairs({TOK.op_plus, TOK.op_minus, TOK.op_times, TOK.op_idiv, TOK.op_div, TOK.op_mod, TOK.op_and, TOK.op_or, TOK.op_xor, TOK.op_ge, TOK.op_gt, TOK.op_le, TOK.op_lt, TOK.op_eq, TOK.op_ne}) do
				if token.children[2].id == k then
					correct = true
					break
				end
			end
			if not correct then
				parse_error(token.children[2].span, 'The second parameter of "reduce(a,b)" must be a binary operator (e.g. + or *)', file)
			end
		elseif token.text == 'clamp' then
			--Convert "clamp" into max(min(upper_bound, x), lower_bound)
			---@type Token
			local node = {
				id = token.id,
				span = token.span,
				text = 'min',
				children = {
					token.children[1],
					token.children[3],
				},
				filename = token.filename,
			}
			token.text = 'max'
			token.children = {node, token.children[2]}
		elseif token.text == 'int' then
			--Convert "int" into floor(num(x))
			---@type Token
			local node = {
				id = token.id,
				span = token.span,
				text = 'num',
				children = token.children,
				filename = token.filename,
			}
			token.text = 'floor'
			token.children = {node}
		elseif token.children then
			for i = 1, #token.children do
				local child = token.children[i]
				if child.id >= TOK.op_plus and child.id <= TOK.op_arrow then
					parse_error(child.span, 'Function "'..token.text..'('..FUNCSIG(token.text)..')" cannot take an operator as a parameter (found "'..child.text..'")', file)
				end
			end
		end
	end)

	--Prep plain (non-interpolated) strings to allow constant folding
	recurse(root, {TOK.string_open}, function(token, file)
		if token.children then
			if token.children[1].id == TOK.text and #token.children == 1 then
				token.value = token.children[1].text
				token.children = nil
			end
		else
			token.value = ''
		end
	end)

	--Check for variable existence by var name, not value
	recurse(root, {TOK.boolean}, function(token, file)
		local ch = token.children[1]
		if token.text == 'exists' and ch.id == TOK.variable then
			ch.id = TOK.string_open
			ch.value = ch.text
			ch.type = 'string'
		end
	end)

	--Get rid of parentheses and expression pseudo-tokens
	recurse(root, {TOK.parentheses, TOK.expression}, nil, function(token, file)
		if not token.children or #token.children ~= 1 then return end

		local child = token.children[1]
		for _, key in ipairs({'value', 'id', 'text', 'span', 'type'}) do
			token[key] = child[key]
		end
		token.children = child.children
	end)

	--Prep text to allow constant folding
	recurse(root, {TOK.text}, function(token, file)
		local val = tonumber(token.text)
		if val then
			token.value = val
			token.type = 'number'
		else
			token.value = token.text
			token.type = 'string'
		end
	end)

	--Make variable assignment make sense, removing quirks of AST generation.
	recurse(root, {TOK.let_stmt}, function(token, file)
		local body = token.children[2]
		if body and body.id == TOK.command then
			if #body.children > 1 then
				body.id = TOK.array_concat
				body.text = '[]'
			else
				token.children[2] = body.children[1]
			end
		end

		--Make sure there are no redundant variable assignments
		if token.children[1].children then
			local vars = {[token.children[1].text] = true}
			for i = 1, #token.children[1].children do
				local child = token.children[1].children[i]
				if child.text ~= '_' and vars[child.text] then
					parse_error(child.span, 'Redundant variable `'..child.text..'` in group assignment. To indicate that this element should be ignored, use an underscore for the variable name.', file)
				end
				vars[child.text] = true
			end
		end
	end)

	--Tidy up WHILE loops and IF/ELIF statements (replace command with cmd contents)
	recurse(root, {TOK.while_stmt, TOK.if_stmt, TOK.elif_stmt}, function(token, file)
		if token.children[1].id ~= TOK.gosub_stmt then
			if #token.children[1].children > 1 then
				parse_error(token.span, 'Too many parameters passed to "'..token.text..'" statement', file)
			end
			token.children[1] = token.children[1].children[1]
		end
	end)

	--Tidy up FOR loops (replace command with cmd contents)
	recurse(root, {TOK.for_stmt}, function(token, file)
		if token.children[2].id == TOK.command then
			if #token.children[2].children > 1 then
				token.children[2].id = TOK.array_concat
			else
				for _, i in ipairs({'text', 'span', 'id', 'value', 'type'}) do
					token.children[2][i] = token.children[2].children[1][i]
				end
				token.children[2].children = token.children[2].children[1].children
			end
		end

		--Don't automatically set var type to "string", let it deduce.
		if token.children[1].id == TOK.text then
			token.children[1].id = TOK.var_assign
			token.children[1].value = nil
			token.children[1].type = nil
		end
	end)

	--Make sure key-value for loops always have some mutation of `pairs()` in the expression.
	recurse(root, {TOK.kv_for_stmt}, function(token, file)
		local node = token.children[3]

		if not node.children or #node.children ~= 1 then
			parse_error(node.span, 'Key-value for loop must be a single `pairs()` expression', file)
		else
			if node.id == TOK.command then
				node = node.children[1]
				token.children[3] = node
			end

			local expr_error = false
			local n = node
			while true do
				if n.id ~= TOK.func_call then
					expr_error = true
					break
				end

				if n.text == 'pairs' then break end

				if n.text ~= 'sort' and n.text ~= 'reverse' then
					expr_error = true
					break
				end

				--This would mean an incorrect amount of params, which will be caught later
				if not n.children or #n.children == 0 then break end

				n = n.children[1]
			end

			if expr_error then
				parse_error(node.span, 'Expression in key-value for loop must contain `pairs()`', file)
			end
		end

		--Don't automatically set var type to "string", let it deduce.
		for i = 1, 2 do
			if token.children[i].id == TOK.text then
				token.children[i].id = TOK.var_assign
				token.children[i].value = nil
				token.children[i].type = nil
			end
		end
	end)

	--[[
		TYPE ANNOTATIONS
	]]
	local variables = {}
	local deduced_variable_types
	local current_sub = nil

	local function type_precheck(token, file)
		if token.id == TOK.subroutine then current_sub = token.text end
	end

	local function type_checking(token, file)
		local signature

		--Unlike other tokens, "command" tokens only need the first child to be constant for us to deduce the type
		if token.id == TOK.inline_command or token.id == TOK.command then
			local ch = token.children[1]

			--subroutine eval is different
			if ch.id == TOK.gosub_stmt then
				if not token.type then
					local lbl = ch.children[1]
					if labels[lbl.text] then token.type = labels[lbl.text].return_type end
				end

				return
			end

			if token.id == TOK.inline_command then ch = ch.children[1] end

			--ignore "define" pseudo-command
			if ch.value == 'define' then return end

			if ch.value ~= nil and ch.id ~= TOK.lit_null and token.id == TOK.command then
				if not ALLOWED_COMMANDS[ch.value] and not BUILTIN_COMMANDS[ch.value] then
					--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
					local msg = 'Unknown command "'..std.str(ch.value)..'"'
					local guess = closest_word(std.str(ch.value), ALLOWED_COMMANDS, 4)
					if guess == nil or guess == '' then
						guess = closest_word(std.str(ch.value), BUILTIN_COMMANDS, 4)
					end

					if guess ~= nil and guess ~= '' then
						msg = msg .. ' (did you mean "'..std.str(guess)..'"?)'
					end
					parse_error(token.span, msg, file)
				end

				if ALLOWED_COMMANDS[ch.value] then
					token.type = ALLOWED_COMMANDS[ch.value]
				else
					token.type = BUILTIN_COMMANDS[ch.value]
				end
			end
			return
		end

		if token.id == TOK.return_stmt then
			local sub = labels[current_sub]
			if sub then
				local exp_type = nil

				if not token.children or #token.children == 0 then
					exp_type = 'null'
				elseif token.children[1].type then
					exp_type = token.children[1].type
				end

				if sub.type and exp_type and exp_type ~= sub.type then
					if sub.type:sub(1,5) == exp_type:sub(1,5) then
						sub.type = 'array'
					else
						sub.type = 'any'
					end
				else
					sub.type = exp_type
				end
			end
			return
		end

		if token.id == TOK.subroutine then
			current_sub = nil
			return
		end

		if token.value ~= nil or token.id == TOK.lit_null then
			token.type = std.deep_type(token.value)
			return
		elseif token.id == TOK.index then
			local c2 = token.children[2]
			if c2.id == TOK.array_slice and #c2.children == 1 then
				c2.unterminated = true
			end

			local t1, t2 = token.children[1].type, token.children[2].type
			if t1 and t2 then
				if t1 ~= 'string' and t1:sub(1,5) ~= 'array' and t1 ~= 'object' and t1 ~= 'any' then
					parse_error(token.children[1].span, 'Cannot index a value of type `'..t1..'`. Type must be `string`, `array`, or `object`', file)
					return
				end

				if t1 == 'string' then
					token.type = t1
				elseif t2:sub(1,5) == 'array' then
					if t1:sub(1,5) == 'array' then token.type = t1 else token.type = 'array' end
				else
					if t1:sub(6,6) == '[' then
						token.type = t1:sub(7, #t1 - 1)
					else
						--We don't know what type of array this is, so result of non-const array index has to be "any"
						token.type = 'any'
					end
				end
			end
			return
		elseif token.id == TOK.variable then
			return
		elseif TYPESIG[token.id] ~= nil then
			signature = TYPESIG[token.id]
		elseif TYPESIG[token.text] ~= nil then
			signature = TYPESIG[token.text]
		else
			return
		end

		if token.children then
			local exp_types, got_types = {}, {}
			local found_correct_types = false

			if signature.valid then
				for g = 1, #signature.valid do
					table.insert(exp_types, {})
				end

				for i = 1, #token.children do
					local tp = token.children[i].type
					if tp then
						for g = 1, #signature.valid do
							local s = signature.valid[g]
							table.insert(exp_types[g], s[(i-1) % #s + 1])
						end
						table.insert(got_types, tp)
					end
				end

				local expt2 = {}
				for i = 1, #exp_types do
					expt2[i] = std.join(exp_types[i], ',')

					found_correct_types = true
					for k = 1, #exp_types[i] do
						local t1, t2 = exp_types[i][k], got_types[k]
						if t1 ~= 'any' and t2 ~= 'any' and t1 ~= t2 then
							if t1:sub(1,5) ~= 'array' or t2:sub(1,5) ~= 'array' then
								found_correct_types = false
								break
							else
								--Compare subtype of arrays
								--If types are not "array[any]" or "array"
								if #t1 > 5 and #t2 > 5 and t1 ~= t2 and t1 ~= 'array[any]' and t2 ~= 'array[any]' then
									found_correct_types = false
								end
								--ELSE:
								--One of the array types are just "array" or "array[any]" (same thing),
								--so we can't tell if they're incompatible at run-time.
								--For all we know they're perfectly compatible.

								break
							end
						end
					end
					if found_correct_types then break end
				end

				if not found_correct_types then
					local msg
					if BUILTIN_FUNCS[token.text] then
						msg = 'Function "'..token.text..'('..FUNCSIG(token.text)..')"'
					else
						msg = 'Operator "'..token.text..'"'
					end
					parse_error(token.span, msg..' expected ('..std.join(expt2, ' or ')..') but got ('..std.join(got_types, ',')..')', file)
				end
			end

			if signature.out then
				if type(signature.out) == 'number' then
					if found_correct_types then token.type = got_types[signature.out] end
				elseif signature.out == 'array' and #token.children > 0 then
					local subtype = token.children[1].type
					for i = 2, #token.children do
						if token.children[i].type ~= subtype then
							subtype = nil
							break
						end
					end
					if subtype then token.type = 'array[' .. subtype .. ']' else token.type = 'array' end
				else
					token.type = signature.out
				end
			end
		end

	end

	local function push_var(var, value)
		if not variables[var] then variables[var] = {} end
		table.insert(variables[var], {
			text = value,
			line = var.span.from.line,
			col = var.span.from.col,
		})
	end

	local function set_var(var, value)
		if not variables[var.text] then variables[var.text] = {} end
		variables[var.text][#variables[var.text]] = {
			text = value,
			line = var.span.from.line,
			col = var.span.from.col,
		}
	end

	local function variable_assignment(token)
		if token.id == TOK.for_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if not var.type then
				--Expression to iterate over is constant
				if ch.value ~= nil or ch.id == TOK.lit_null then
					local tp

					if type(ch.value) == 'table' then
						for _, val in pairs(ch.value) do
							local _tp = std.deep_type(val)
							if tp == nil then tp = _tp
							elseif tp ~= _tp then
								--Type will change, so it can't be reduced to a constant state.
								--Maybe change this later?
								tp = nil
								break
							end
						end
					else
						tp = std.deep_type(ch.value)
					end

					--If loop variable has a consistent type, then we know for sure what it will be.
					if tp ~= nil then
						push_var(var, tp)
						var.type = tp
						deduced_variable_types = true
					end
				end
			end
		end
	end

	local function variable_unassignment(token)
		if token.id == TOK.for_stmt then
			local var = token.children[1].text
			local ch = token.children[2]
			if variables[var] then
				if #variables[var] == 1 then
					variables[var] = nil
				else
					table.remove(variables)
				end
			end

			if ch.type and ch.type:sub(1,5) == 'array' and ch.type:sub(6,6) == '[' then
				token.children[1].type = ch.type:sub(7, #ch.type - 1)
			end
		elseif token.id == TOK.kv_for_stmt then
			local key, value, expr = token.children[1], token.children[2], token.children[3]

			for _, i in ipairs({key.text, value.text}) do
				if variables[i] then
					if #variables[i] == 1 then
						variables[i] = nil
					else
						table.remove(variables)
					end
				end
			end

			if not key.type then
				local found_pairs = false
				while expr do
					if found_pairs then
						if expr.type then
							value.type = 'any'
							if expr.type == 'object' then
								key.type = 'string'
							elseif expr.type:sub(1,5) == 'array' then
								key.type = 'number'
								if expr.type:sub(6,6) == '[' then
									value.type = expr.type:sub(7, #expr.type - 1)
								end
							end
						end
						break
					end

					if expr.id ~= TOK.func_call or (expr.text ~= 'pairs' and expr.text ~= 'reverse' and expr.text ~= 'sort') then
						break
					end

					if expr.text == 'pairs' then found_pairs = true end

					expr = expr.children[1]
				end
			end

		elseif token.id == TOK.let_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if var.type then return end

			if #token.children > 2 then
				--Don't deduce types for let statements that are updating variables.
				--Those don't define what the variable's actual type is.
				return
			end

			local tp = nil
			if ch and ch.type then tp = ch.type end

			if var.children then
				local vars = {var.text}
				for i = 1, #var.children do
					table.insert(vars, var.children[i].text)
				end

				for i = 1, #vars do
					tp = nil
					if ch then
						if ch.id == TOK.array_concat then
							if ch.children[i] and ch.children[i].type then
								tp = ch.children[i].type
							end
						elseif ch.value or ch.id == TOK.lit_null then
							if ch.id == TOK.lit_array then
								tp = std.deep_type(ch.value[i])
							elseif i == 1 then
								tp = std.deep_type(ch.value)
							else
								tp = 'null'
							end
						else
							tp = 'any'
						end
					else
						tp = 'null'
					end

					if tp ~= nil then
						local child = var
						if i > 1 then child = var.children[i-1] end
						set_var(child, tp)
						child.type = tp
						deduced_variable_types = true
					end
				end
			elseif tp ~= nil then
				set_var(var, tp)
				var.type = tp
				deduced_variable_types = true
			end

		elseif token.id == TOK.variable then
			if token.type then return end

			local tp = variables[token.text]
			if tp then
				local tp1 = tp[#tp]
				if tp1.line > token.span.from.line or (tp1.line == token.span.from.line and tp1.col > token.span.from.col) then
					if #tp < 2 then return end
					token.type = tp[#tp - 1].text
				else
					token.type = tp[#tp].text
				end
			elseif token.text == '$' then
				token.type = 'array[string]'
			elseif token.text == '@' then
				token.type = 'array'
			end
		end
	end

	--Check what variables are never assigned or never referenced
	local assigned_vars = {
		['$'] = {},
		['@'] = {},
	}
	local this_var = nil
	recurse(root, {TOK.var_assign, TOK.inline_command}, function(token, file)
		local ix = token.span.from
		if token.id == TOK.var_assign then
			this_var = token.text
			token.ignore = true --If this variable is not used anywhere, we can optimize it away.
			if not assigned_vars[this_var] then assigned_vars[this_var] = {} end
			assigned_vars[this_var][ix.line..'|'..ix.col] = token
		elseif this_var then
			local cmd = nil
			if token.children[1].id == TOK.command then cmd = token.children[1].children[1].text end
			--If the command has no side-effects, we CAN still optimize them away.
			if cmd ~= 'time' and cmd ~= 'systime' and cmd ~= 'sysdate' then
				--We CAN'T fully optimize this variable away because it has a command eval in it.
				for _, var_decl in pairs(assigned_vars[this_var]) do var_decl.ignore = false end
			end
		end
	end, function(token, file)
		if token.id == TOK.var_assign then this_var = nil end
	end)
	recurse(root, {TOK.variable, TOK.list_comp}, function(token, file)
		if token.id == TOK.list_comp then
			local child = token.children[2]
			local ix = child.span.from
			if not assigned_vars[child.text] then assigned_vars[child.text] = {} end
			assigned_vars[child.text][ix.line..'|'..ix.col] = child
			return
		end

		if assigned_vars[token.text] then
			for _, var_decl in pairs(assigned_vars[token.text]) do var_decl.is_referenced = true end
		else
			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				INFO.warning(token.span, 'Variable is never declared', file)
			end
			--[[/minify-delete]]
			--Using a variable that is never declared.
			token.ignore = true
		end
	end, function(token, file)
		if token.id == TOK.list_comp then
			local child = token.children[2]
			local ix = child.span.from

			assigned_vars[child.text][ix.line..'|'..ix.col] = nil
			if next(assigned_vars[child.text]) == nil then assigned_vars[child.text] = nil end
		end
	end)
	--[[minify-delete]]
	--TODO: MAKE SURE CORRECT FILE!!!
	if _G['LANGUAGE_SERVER'] then
		for _, decls in pairs(assigned_vars) do
			for _, var_decl in pairs(decls) do
				if not var_decl.is_referenced and not _G['EXPORT_LINES'][var_decl.span.from.line] then
					local filename = root_file
					if var_decl.filename then filename = var_decl.filename end
					if var_decl.text:sub(1,1) ~= '_' then
						INFO.warning(var_decl.span, 'Variable is never used. To indicate that this is intentional, prefix with an underscore', filename)
					end
					INFO.dead_code(var_decl.span, '', filename)
				end
			end
		end
	end
	--[[/minify-delete]]

	--[[
		CONSTANT FOLDING AND TYPE DEDUCTIONS
	]]
	deduced_variable_types = true
	while deduced_variable_types do
		deduced_variable_types = false

		--First pass at deducing all types
		recurse(root, {TOK.string_open, TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.index, TOK.array_concat, TOK.array_slice, TOK.comparison, TOK.negate, TOK.func_call, TOK.concat, TOK.length, TOK.lit_array, TOK.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.inline_command, TOK.command, TOK.return_stmt, TOK.subroutine}, type_precheck, type_checking)

		--Fold constants. this improves performance at runtime, and checks for type errors early on.
		if not ERRORED then recurse(root, {TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.length, TOK.func_call, TOK.array_concat, TOK.negate, TOK.comparison, TOK.concat, TOK.array_slice, TOK.string_open, TOK.index, TOK.ternary, TOK.list_comp, TOK.object, TOK.key_value_pair}, nil, FOLD_CONSTANTS) end

		--Set any variables we can
		if not ERRORED then recurse(root, {TOK.for_stmt, TOK.kv_for_stmt, TOK.let_stmt, TOK.variable}, variable_assignment, variable_unassignment) end

		if ERRORED then break end
	end

	if not ERRORED then
		--One last pass at deducing all types (after any constant folding)
		recurse(root, {TOK.string_open, TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.index, TOK.array_concat, TOK.array_slice, TOK.comparison, TOK.negate, TOK.func_call, TOK.concat, TOK.length, TOK.lit_array, TOK.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.variable, TOK.inline_command, TOK.command, TOK.return_stmt, TOK.subroutine}, nil, type_checking)
	end

	--If running as language server, print type info for any variable declarations or command calls.
	--[[minify-delete]]
	if _G['LANGUAGE_SERVER'] then
		recurse(root, {TOK.let_stmt, TOK.for_stmt, TOK.kv_for_stmt, TOK.inline_command, TOK.command, TOK.subroutine}, function(token, file)
			local var = token.children[1]
			if token.id == TOK.inline_command or token.id == TOK.command then
				local cmd = var
				if token.id == TOK.inline_command then cmd = cmd.children[1] end

				if cmd.value then
					if var.id == TOK.gosub_stmt then
						if labels[cmd.text] then
							INFO.hint(cmd.span, 'Subroutine `'..cmd.text..'` defined on line '..labels[cmd.text].span.from.line..', col '..labels[cmd.text].span.from.col, file)
							local tp = labels[cmd.text].type
							if tp == 'null' then
								INFO.info(cmd.span, 'Subroutine `'..cmd.text..'` always returns null, so using an inline command eval here is not helpful', file)
							elseif tp then
								INFO.hint(cmd.span, 'returns: '..tp, file)
							end
						end
					else
						local tp
						if ALLOWED_COMMANDS[cmd.value] then
							tp = ALLOWED_COMMANDS[cmd.value]
						else
							tp = BUILTIN_COMMANDS[cmd.value]
						end

						if token.id == TOK.command and tp then
							INFO.hint(cmd.span, _G['CMD_DESCRIPTION'][cmd.text], file)
							INFO.hint(cmd.span, 'returns: '..tp, file)
						end

						if token.id == TOK.inline_command and tp == 'null' then
							INFO.info(cmd.span, 'Command `'..cmd.text..'` always returns null, so using an inline command eval here is not helpful', file)
						end
					end
				end
			elseif token.id == TOK.subroutine then
				if token.type then INFO.hint(token.span, 'returns: '..token.type, file) end
			elseif token.id == TOK.kv_for_stmt then
				if var.type then INFO.hint(var.span, 'type: '..var.type, file) end
				var = token.children[2]
				if var.type then INFO.hint(var.span, 'type: '..var.type, file) end
			else
				while var do
					if var.type then INFO.hint(var.span, 'type: '..var.type, file) end

					---@diagnostic disable-next-line: cast-local-type
					if var.children then var = var.children[1] else var = nil end
				end
			end
		end)
	end
	--[[/minify-delete]]

	--Restructure match statements into an equivalent if/elif/else block.
	recurse(root, {TOK.match_stmt}, function(token, file)
		local iter = {token.children[2]}
		if iter[1].id == TOK.program then iter = iter[1].children end

		if iter == nil then
			parse_error(token.span, 'COMPILER BUG: Match statement has no comparison branches!', file)
			return
		end

		local constant = token.children[1].value ~= nil or token.children[1].id == TOK.lit_null

		token.id = TOK.program
		local var = LABEL_ID()

		---@type Token
		local condition = {
			id = TOK.let_stmt,
			text = 'let',
			span = token.span,
			children = {
				{
					id = TOK.var_assign,
					text = var,
					span = token.span,
				},
				token.children[1],
			}
		}

		local else_branch = token.children[3]
		for i = #iter, 1, -1 do
			iter[i].children[3] = else_branch
			else_branch = iter[i]

			--Optimization: allow branch pruning if the
			local compare_node = token.children[1]
			if not constant then
				compare_node = {
					id = TOK.variable,
					text = var,
					span = else_branch.children[1].span,
				}
			end

			else_branch.children[1] = {
				id = TOK.comparison,
				text = '==',
				span = else_branch.children[1].span,
				children = {
					compare_node,
					else_branch.children[1],
				},
			}
		end

		if constant then
			token.children = {else_branch}

			--If branch condition is constant, try to fold constants one more time.
			--This improves performance at runtime, and can allow branches to be pruned at compile time.
			if not ERRORED then recurse(root, {TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.length, TOK.func_call, TOK.array_concat, TOK.negate, TOK.comparison, TOK.concat, TOK.array_slice, TOK.string_open, TOK.index, TOK.ternary, TOK.list_comp, TOK.object, TOK.key_value_pair}, nil, FOLD_CONSTANTS) end
		else
			token.children = {condition, else_branch}
		end
	end)

	--Remove the body of conditionals that will never get executed
	recurse(root, {TOK.if_stmt, TOK.elif_stmt}, function(token, file)
		local cond = token.children[1]
		if cond.value ~= nil or cond.id == TOK.lit_null then
			--Decide whether to remove "then" or "else" branch
			local ix, id, text = 2, TOK.kwd_then, 'then'
			if std.bool(cond.value) then
				ix, id, text = 3, TOK.kwd_end, 'end'
			end

			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				if token.children[ix].id == TOK.kwd_end then return end
				INFO.dead_code(token.children[ix].span, '', file)
			end
			--[[/minify-delete]]

			--[[minify-delete]] if not _G['KEEP_DEAD_CODE'] then --[[/minify-delete]]
			token.children[ix] = {
				id = id,
				span = token.children[ix].span,
				text = text,
			}
			--[[minify-delete]] end --[[/minify-delete]]
		end
	end)

	--Remove the body of loops that will never get executed
	recurse(root, {TOK.while_stmt}, function(token, file)
		local cond = token.children[1]
		if (cond.value ~= nil or cond.id == TOK.lit_null) and not std.bool(cond.value) then
			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				INFO.dead_code(token.span, '', file)
			end
			--[[/minify-delete]]

			--[[minify-delete]] if not _G['KEEP_DEAD_CODE'] then --[[/minify-delete]]
			token.children = { cond }
			--[[minify-delete]] end --[[/minify-delete]]
		end
	end)
	recurse(root, {TOK.for_stmt}, function(token, file)
		local iter = token.children[2]
		if type(iter.value) == 'table' and next(iter.value) == nil then
			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				INFO.dead_code(token.span, '', file)
			end
			--[[/minify-delete]]

			--[[minify-delete]] if not _G['KEEP_DEAD_CODE'] then --[[/minify-delete]]
			token.children[3] = nil
			--[[minify-delete]] end --[[/minify-delete]]
		end
	end)

	--Make sure BREAK and CONTINUE statements can actually break out of the number of specified loops
	local loop_depth = 0
	recurse(root, {TOK.while_stmt, TOK.for_stmt, TOK.kv_for_stmt, TOK.break_stmt, TOK.continue_stmt}, function(token, file)
		if token.id == TOK.break_stmt or token.id == TOK.continue_stmt then
			local loop_out = token.children[1].value
			if loop_out > loop_depth then
				local phrase, plural, amt = 'break out', '', 'only '..loop_depth
				if token.id == TOK.continue_stmt then phrase = 'skip iteration' end
				if loop_out ~= 1 then plural = 's' end
				if loop_depth == 0 then amt = 'none' end
				parse_error(token.span, 'Unable to '..phrase..' of '..loop_out..' loop'..plural..', '..amt..' found at this scope', file)
			end
		end

		loop_depth = loop_depth + 1
	end, function(token, file)
		loop_depth = loop_depth - 1
	end)

	--Check if subroutines are even used
	--We also keep track of what subroutines each subroutine references.
	--This lets us remove recursive subroutines, or subs that reference each other
	local sub_refs = {}
	local top_level_subs = {}
	local current_sub = nil
	recurse(root, {TOK.gosub_stmt, TOK.subroutine}, function(token, file)
		if token.id == TOK.gosub_stmt then
			local text = token.children[1].text

			if current_sub then
				if not sub_refs[current_sub] then sub_refs[current_sub] = {} end
				table.insert(sub_refs[current_sub], text)
			else
				local sub = labels[text]
				if sub then sub.is_referenced = true end
				top_level_subs[text] = true
			end
		else
			current_sub = token.text
		end
	end, function(token, file)
		if token.id == TOK.subroutine then current_sub = nil end
	end)

	--Scan through subroutines and check if we can trace gosubs from the top level down to each subroutine.
	--If we can, then we CANNOT optimize the subroutine away.
	local function trace_subs(parent, children, top_parent)
		for _, child in ipairs(children) do
			if child ~= parent and child ~= top_parent then
				local sub = labels[child]
				if sub then sub.is_referenced = true end
				if sub_refs[child] then trace_subs(child, sub_refs[child], top_parent) end
			end
		end
	end
	for label, _ in pairs(top_level_subs) do
		if sub_refs[label] then trace_subs(label, sub_refs[label], label) end
	end

	--Check gosub uses. Gosub IS allowed to have a single, constant value as its parameter.
	recurse(root, {TOK.gosub_stmt}, function(token, file)
		local label
		if token.children[1].value ~= nil or token.children[1].id == TOK.lit_null then
			label = std.str(token.children[1].value)
		elseif token.children[1].id == TOK.text then
			label = token.children[1].text
		end

		if label == nil then
			local kid = token.children[1]

			--Check if the dynamic gosub could never possibly hit certain subroutines
			---@type table|nil
			local begins, ends, contains = nil, nil, {}
			if kid and kid.children and kid.children[1] then
				begins = kid.children[1]
				ends = kid.children[#kid.children]
				for i = 2, #kid.children - 1 do
					if kid.children[i].value ~= nil then
						table.insert(contains, std.str(kid.children[i].value))
					end
				end
			end

			if begins and (begins.value ~= nil or begins.id == TOK.lit_null) then begins = {value = begins.text} end
			if ends and (ends.value ~= nil or ends.id == TOK.lit_null) then ends = {value = ends.text} end

			--If we have a dynamic gosub then we can't remove any subroutines, as we don't really know what subroutine is referenced.
			for k, i in pairs(labels) do
				local begins_with = begins and k:sub(1, #std.str(begins.value)) == begins.value
				local ends_with = ends and k:sub(#k - #std.str(ends.value) + 1, #k) == ends.value
				local does_contain = #contains == 0 and (not begins or not begins.value) and (not ends or not ends.value) --If there are no const parts, then we can't know.

				for j = 1, #contains do
					if std.contains(k, contains[j]) then does_contain = true end
				end

				if begins_with or ends_with or does_contain then
					i.is_referenced = true
				end
			end
			return
		end

		if labels[label] == nil then
			local msg = 'Subroutine `'..label..'` not declared anywhere'
			local guess = closest_word(label, labels, 4)
			if guess ~= nil and guess ~= '' then
				msg = msg .. ' (did you mean "'.. guess ..'"?)'
			end
			parse_error(token.children[1].span, msg, file)
		else
			token.ignore = labels[label].ignore
		end
	end)

	--Warn if subroutines are not used.
	--[[minify-delete]]
	if _G['LANGUAGE_SERVER'] then
		recurse(root, {TOK.subroutine}, function(token, file)
			if not token.is_referenced and not _G['EXPORT_LINES'][token.span.from.line] then
				local span = {
					from = token.span.from,
					to = {
						line = token.span.to.line,
						col = token.span.to.col - 4,
					}
				}

				INFO.dead_code(span, 'Subroutine `'..token.text..'` is never used.', file)
			end
		end)
	end
	--[[/minify-delete]]

	--Remove dead code after stop, return, continue, or break statements
	recurse(root, {TOK.program}, function(token, file)
		local dead_code_span = nil

		for i = 1, #token.children do
			if dead_code_span then
				--[[minify-delete]] if not _G['KEEP_DEAD_CODE'] then --[[/minify-delete]]
				token.children[i] = nil
				--[[minify-delete]] end --[[/minify-delete]]
			else
				local node = token.children[i]
				if node.id == TOK.kwd_stop or node.id == TOK.return_stmt or node.id == TOK.continue_stmt or node.id == TOK.break_stmt then
					--if this is not the last statement in the list,
					--then mark all future statements as dead code.
					if i < #token.children then
						dead_code_span = {
							from = token.children[i+1].span.from,
							to = token.children[#token.children].span.to,
						}
					end
				end
			end
		end

		--[[minify-delete]]
		if _G['LANGUAGE_SERVER'] and dead_code_span then
			--Warn about dead code
			INFO.dead_code(dead_code_span, 'Dead code', file)
		end
		--[[/minify-delete]]
	end)

	if ERRORED then terminate() end

	return root
end
