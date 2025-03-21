FUNC_OPERATIONS = {
	bytes = function(number, count)
		local result = {}
		for i = math.min(4, count), 1, -1 do
			result[i] = math.floor(number) % 256
			number = number / 256
		end
		return result
	end,

	frombytes = function(values)
		local result = 0
		for i = 1, #values do
			result = result * 256 + values[i]
		end
		return result
	end,

	sum = function(values)
		local total = 0
		for i = 1, #values do
			if type(values[i]) == 'table' then
				for k = 1, #values[i] do
					total = total + values[i][k]
				end
			else
				total = total + values[i]
			end
		end
		return total
	end,
	mult = function(values)
		local total = 1
		for i = 1, #values do
			if type(values[i]) == 'table' then
				for k = 1, #values[i] do
					total = total * values[i][k]
				end
			else
				total = total * values[i]
			end
		end
		return total
	end,
	min = function(values, token, file)
		if #values == 0 then
			parse_error(token.span, 'Function min(...) requires at least one value', file)
		end

		local target = nil
		for i = 1, #values do
			if type(values[i]) == 'table' then
				for k = 1, #values[i] do
					if type(values[i][k]) ~= 'number' then
						parse_error(token.span, 'All values passed to min(...) must be numeric', file)
						return 0
					end

					if target then target = math.min(target, values[i][k]) else target = values[i][k] end
				end
			else
				if type(values[i]) ~= 'number' then
					parse_error(token.span, 'All values passed to min(...) must be numeric', file)
					return 0
				end
				if target then target = math.min(target, values[i]) else target = values[i] end
			end
		end

		return target
	end,
	max = function(values, token, file)
		if #values == 0 then
			parse_error(token.span, 'Function max(...) requires at least one value', file)
		end

		local target = nil
		for i = 1, #values do
			if type(values[i]) == 'table' then
				for k = 1, #values[i] do
					if type(values[i][k]) ~= 'number' then
						parse_error(token.span, 'All values passed to max(...) must be numeric', file)
						return 0
					end

					if target then target = math.max(target, values[i][k]) else target = values[i][k] end
				end
			else
				if type(values[i]) ~= 'number' then
					parse_error(token.span, 'All values passed to max(...) must be numeric', file)
					return 0
				end
				if target then target = math.max(target, values[i]) else target = values[i] end
			end
		end

		return target
	end,
	clamp = function(value, min, max) return math.min(max, math.max(min, value)) end,
	smoothstep = function(value, min, max)
		local range = max - min
		value = (math.min(math.max(min, value), max) - min) / range
		value = value * value * (3.0 - 2.0 * value)
		return value * range + min
	end,
	lerp = function(x, a, b) return a + x * (b - a) end,
	-- pow = function(a, b) return a ^ b end,
	bool = function(data) return std.bool(data) end,
	str = function(data) return std.str(data) end,
	num = function(data) return std.num(data) end,
	word_diff = function(a, b, token, file) return lev(a, b) end,
	split = function(a, b) return std.split(a, b) end,
	join = function(a, b) return std.join(a, b) end,
	type = function(a) return std.type(a) end,
	dist = function(a, b, token, file)
		if type(a) ~= type(b) then
			parse_error(token.span,
				'Function "dist(a,b)" expected (number, number) or (array, array) but got (' ..
				std.type(a) .. ', ' .. std.type(b) .. ')', file)
		end

		if type(a) == 'number' then
			return math.abs(b - a)
		end

		if #a ~= #b then
			parse_error(token.span, 'Function "dist(a,b)" expected arrays of equal length, got lengths ' ..
				#a .. ' and ' .. #b, file)
		end

		local total = 0
		for i = 1, #a do
			local p = a[i] - b[i]
			total = total + p * p
		end
		return math.sqrt(total)
	end,
	append = function(a, b)
		table.insert(a, b)
		return a
	end,
	index = function(a, b)
		if type(a) == 'table' then
			return std.arrfind(a, b, 1)
		else
			return std.strfind(a, std.str(b), 1)
		end
	end,
	lower = function(a)
		return std.str(a):lower()
	end,
	upper = function(a)
		return std.str(a):lower()
	end,
	camel = function(a)
		return a:gsub('(%l)(%w*)', function(x, y) return x:upper() .. y end)
	end,
	replace = function(subject, search, replace)
		--Not really memory efficient, but good enough.
		return std.join(std.split(subject, search), replace)
	end,

	json_encode = function(data, token, file)
		local indent = nil
		if data[2] then indent = 2 end

		local result, err = json.stringify(data[1], indent, true)

		if err ~= nil then
			parse_error(token.span, err, file)
		end

		return result
	end,
	json_decode = function(data, token, file)
		local result, err = json.parse(data, true)

		if err ~= nil then
			parse_error(token.span, err, file)
		end

		return result
	end,

	json_valid = json.verify,
	b64_encode = std.b64_encode,
	b64_decode = std.b64_decode,

	lpad = function(text, character, width)
		local c = character:sub(1, 1)
		return c:rep(width - #text) .. text
	end,
	rpad = function(text, character, width)
		local c = character:sub(1, 1)
		return text .. c:rep(width - #text)
	end,
	hex = function(value)
		return string.format('%x', value)
	end,

	filter = function(text, pattern)
		return std.filter(text, pattern)
	end,
	matches = function(text, pattern)
		local array = std.array()
		for i in text:gmatch(pattern) do
			table.insert(array, i)
		end
		return array
	end,
	clocktime = function(value)
		local result = {
			math.floor(value / 3600),
			math.floor(value / 60) % 60,
			math.floor(value) % 60,
		}
		local millis = math.floor(value * 1000) % 1000
		if millis ~= 0 then result[4] = millis end
		return result
	end,

	reverse = function(value)
		if type(value) == 'string' then
			return value:reverse()
		end

		local result = {}
		for i = #value, 1, -1 do
			table.insert(result, value[i])
		end
		return result
	end,
	sort = function(value)
		local is_table = false
		for key, val in pairs(value) do
			if type(val) == 'table' then
				is_table = true
				break
			end
		end
		if is_table then
			table.sort(value, function(a, b) return std.str(a) < std.str(b) end)
		else
			table.sort(value)
		end
		return value
	end,
	merge = function(array1, array2)
		for i = 1, #array2 do
			table.insert(array1, array2[i])
		end
		return array1
	end,
	update = function(array, index, value)
		array[index] = value
		return array
	end,
	insert = function(array, index, value)
		table.insert(array, index, value)
		return array
	end,
	delete = function(array, index)
		table.remove(array, index)
		return array
	end,

	hash = std.hash,

	--Object-related functions
	object = function(array)
		local result = std.object()
		for i = 1, #array, 2 do
			result[std.str(array[i])] = array[i + 1]
		end
		return result
	end,
	array = function(object)
		local result = {}
		for key, value in pairs(object) do
			table.insert(result, key)
			table.insert(result, value)
		end
		return result
	end,

	keys = function(object)
		local result = {}
		for key, value in pairs(object) do table.insert(result, key) end
		return result
	end,
	values = function(object)
		local result = {}
		for key, value in pairs(object) do table.insert(result, value) end
		return result
	end,
	pairs = function(object)
		local result = {}
		for key, value in pairs(object) do table.insert(result, { key, value }) end
		return result
	end,

	interleave = function(array1, array2)
		local result, length = {}, math.min(#array1, #array2)
		for i = 1, length do
			table.insert(result, array1[i])
			table.insert(result, array2[i])
		end

		for i = length + 1, #array1 do table.insert(result, array1[i]) end
		for i = length + 1, #array2 do table.insert(result, array2[i]) end
		return result
	end,

	unique = std.unique,
	union = std.union,
	intersection = std.intersection,
	difference = std.difference,
	symmetric_difference = std.symmetric_difference,
	is_disjoint = std.is_disjoint,
	is_subset = std.is_subset,
	is_superset = function(array1, array2)
		return std.is_subset(array2, array1)
	end,

	count = function(a, b)
		if type(a) == 'table' then
			return std.arrcount(a, b)
		else
			return std.strcount(a, std.str(b))
		end
	end,

	find = function(a, b, n)
		if type(a) == 'table' then
			return std.arrfind(a, b, n)
		else
			return std.strfind(a, std.str(b), n)
		end
	end,

	flatten = function(array)
		local result = std.array()
		for i = 1, #array do
			if type(array[i]) == 'table' then
				local flat = FUNC_OPERATIONS.flatten(array[i])
				for k = 1, #flat do table.insert(result, flat[k]) end
			else
				table.insert(result, array[i])
			end
		end
		return result
	end,

	sign = std.sign,
	ascii = function(char) return char:byte(1) end,
	char = function(ascii) return string.char(ascii) end,

	beginswith = function(search, substring)
		return search:sub(1, #substring) == substring
	end,
	endswith = function(search, substring)
		return search:sub(#search - #substring + 1, #search) == substring
	end,
	numeric_string = std.numeric_string,

	time = function(timestamp)
		if type(timestamp) == 'number' then timestamp = FUNC_OPERATIONS.clocktime(timestamp) end
		local result = ''
		for i = 1, #timestamp do
			if i > 3 then
				result = result .. '.'
			elseif #result > 0 then
				result = result .. ':'
			end
			local val = tostring(std.num(timestamp[i]))
			result = result .. ('0'):rep(2 - #val) .. val
		end
		return result
	end,

	date = function(array)
		local result = ''
		for i = #array, 1, -1 do
			if #result > 0 then result = result .. '-' end
			local val = tostring(std.num(array[i]))
			result = result .. ('0'):rep(2 - #val) .. val
		end
		return result
	end,

	match = function(text, pattern)
		return text:match(pattern)
	end,

	splice = function(array1, index1, index2, array2)
		local result = std.array()
		for i = 1, index1 - 1 do table.insert(result, array1[i]) end
		for i = 1, #array2 do table.insert(result, array2[i]) end
		for i = index2 + 1, #array1 do table.insert(result, array1[i]) end
		return result
	end,

	glob = function(values)
		local pattern = values[1]
		local result = std.array()

		for i = 2, #values do
			if std.type(values[i]) == 'array' then
				for k = 1, #values[i] do
					local val = pattern:gsub("%*", std.str(values[i][k]))
					table.insert(result, val)
				end
			else
				local val = pattern:gsub("%*", std.str(values[i]))
				table.insert(result, val)
			end
		end

		return result
	end,

	xml_encode = XML.stringify,
	xml_decode = XML.parse,
}
