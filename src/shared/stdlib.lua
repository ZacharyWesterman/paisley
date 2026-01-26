--This is a "standard library" of sorts, containing code that's shared between the Paisley compiler and runtime engine.

require "src.shared.hash"

---@diagnostic disable-next-line
std = {
	---Convert arbitrary data to a string, with "Lua-ness" removed.
	---@param data any
	---@return string
	str = function(data)
		if data == nil then return '' end
		if data == true then return '1' end
		if data == false then return '0' end

		if std.type(data) == 'array' then
			local result = ''
			local first = true
			for i = 1, #data do
				if not first then result = result .. ' ' end
				result = result .. std.str(data[i])
				first = false
			end
			return result
		elseif std.type(data) == 'object' then
			local result = ''
			local first = true
			for key, value in pairs(data) do
				if not first then result = result .. ' ' end
				result = result .. std.str(key) .. ' ' .. std.str(value)
				first = false
			end
			return result
		end
		return tostring(data)
	end,

	---Convert arbitrary data to a string with all debug information.
	---@param data any
	---@return string
	debug_str = function(data)
		if type(data) == 'table' then
			local result = ''
			local meta = getmetatable(data)
			local first = true
			for key, value in pairs(data) do
				if not first then result = result .. ',' end
				if meta and meta.is_array == false then result = result .. std.debug_str(key) .. ':' end
				result = result .. std.debug_str(value)
				first = false
			end
			return '{' .. result .. '}'
		elseif type(data) == 'string' then
			return '"' .. data .. '"'
		elseif type(data) == 'boolean' then
			if data then return 'true' else return 'false' end
		elseif data == nil then
			return 'null'
		else
			return std.str(data)
		end
	end,

	---Cast data to a boolean.
	---Empty strings, empty arrays, empty objects, nil, false and zero all convert to false. Any other values convert to true.
	---@param data any
	---@return boolean
	bool = function(data)
		local tp = std.type(data)
		if tp == 'object' then
			for key, val in pairs(data) do return true end
			return false
		elseif tp == 'array' then
			return #data > 0
		end

		return data and data ~= 0 and data ~= ''
	end,

	---Cast data to a number.
	---Numbers and purely numeric strings will convert to the appropriate number.
	---True and false convert to 1 and 0 respectively.
	---Any other values convert to 0.
	---@param data any
	---@return number
	num = function(data --[[any]])
		if data == true then return 1 end
		local val = tonumber(data)
		if val == nil then return 0 else return val end
	end,

	---Cast data to a value that can be compared with >, <, >=, <=.
	---Anything that's not a number or a string will be converted to a string.
	---@param data1 any
	---@param data2 any
	---@param operation fun(param1: number|string, param2: number|string): boolean
	---@return boolean
	compare = function(data1, data2, operation)
		local tp1, tp2 = type(data1), type(data2)
		if tp1 == 'table' then data1 = std.str(data1) elseif tp1 ~= 'string' then data1 = std.num(data1) end
		if tp2 == 'table' then data2 = std.str(data2) elseif tp1 ~= 'string' then data2 = std.num(data2) end

		if type(data1) ~= type(data2) then
			data1 = std.str(data1)
			data2 = std.str(data2)
		end
		return operation(data1, data2)
	end,

	---Join an array of items into a string.
	---@param items any[] The items to join into a string.
	---@param delimiter string The delimiter between items.
	---@param converter? fun(data: any): string A function that converts the given data to a string.
	---@return string
	join = function(items, delimiter, converter)
		if not converter then converter = std.str end
		local result = ''
		for i = 1, #items do
			if i > 1 then result = result .. delimiter end
			result = result .. converter(items[i])
		end
		return result
	end,

	---Get the type of some data, with the "Lua-ness" removed.
	---Types will include one of "object" or "array" instead of table.
	---@param data any
	---@return string
	type = function(data)
		if data == nil then return 'null' end
		if type(data) == 'table' then
			local meta = getmetatable(data)
			if meta and not meta.is_array then return 'object' else return 'array' end
		end
		return type(data)
	end,

	deep_type = function(data)
		local tp = std.type(data)

		if tp == 'array' and #data > 0 then
			local subtype = std.deep_type(data[1])
			local found = { [subtype] = true }

			for i = 2, #data do
				local s_tp = std.deep_type(data[i])
				if not found[s_tp] then
					subtype = subtype .. '|' .. s_tp
					found[s_tp] = true
				end
			end

			tp = tp .. '[' .. subtype .. ']'
		end

		return tp
	end,

	---Split a string by delimiter.
	---@param text string
	---@param delimiter string
	---@return string[]
	split = function(text, delimiter)
		--Why am I writing my own split function?
		--1. Lua doesn't have a built-in one.
		--2. I do NOT want users to have to think about regex.
		--3. I just want a normal split function, literally every other language has one, or at least a normal FIND FUNCTION?? why can't Lua be normal???

		if text == '' then return {} end

		local result = {}

		if delimiter == '' then
			local ch
			for ch in text:gmatch('.') do
				table.insert(result, ch)
			end
			return result
		end

		while #text > 0 do
			local i
			local found = false

			for i = 1, #text - #delimiter + 1 do
				if text:sub(i, i + #delimiter - 1) == delimiter then
					table.insert(result, text:sub(1, i - 1))
					text = text:sub(i + #delimiter, #text)
					found = true
					break
				end
			end

			if not found then
				table.insert(result, text)
				break
			end
		end

		return result
	end,

	---Check if a string contains a given substring.
	---@param text string
	---@param substring string
	---@return boolean
	contains = function(text, substring)
		local i
		for i = 1, #text - #substring + 1 do
			if text:sub(i, i + #substring - 1) == substring then
				return true
			end
		end
		return false
	end,

	---Find the nth occurrence of a given substring.
	---@param text string The string to search.
	---@param substring string The substring to search for.
	---@param occurrence integer The nth occurrence to find.
	---@return integer
	strfind = function(text, substring, occurrence)
		local ct, i = 0, 1
		while i <= #text do
			if text:sub(i, i + #substring - 1) == substring then
				ct = ct + 1
				if ct >= occurrence then return i end
				i = i + #substring
			else
				i = i + 1
			end
		end
		return 0
	end,

	---Find the nth occurrence of a value in an array.
	---@param array table The array to search.
	---@param value any The value to search for.
	---@param occurrence integer The nth occurrence to find.
	---@return integer
	arrfind = function(array, value, occurrence)
		local ct = 0
		for i = 1, #array do
			if array[i] == value then
				ct = ct + 1
				if ct >= occurrence then return i end
			end
		end
		return 0
	end,

	---@about Count the number of occurrences of a given substring in a string.
	---@param text string The string to search.
	---@param substring string The substring to search for.
	---@return integer
	strcount = function(text, substring)
		local ct, i = 0, 1
		while i <= #text do
			if text:sub(i, i + #substring - 1) == substring then
				i = i + #substring
				ct = ct + 1
			else
				i = i + 1
			end
		end
		return ct
	end,

	---Count the number of occurrences of a given value in an array.
	---@param array table The array to search.
	---@param value any The value to search for.
	---@return integer
	arrcount = function(array, value)
		local ct = 0
		for i = 1, #array do
			if array[i] == value then
				ct = ct + 1
			end
		end
		return ct
	end,

	---Decode a base64-encoded string.
	---@param data string The base64-encoded string.
	---@return string
	b64_encode = function(data)
		--[[Source: http://lua-users.org/wiki/BaseSixtyFour]]
		local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		return ((data:gsub('.', function(x)
			local r, b = '', x:byte()
			for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
			return r
		end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c = 0
			for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
			return b:sub(c + 1, c + 1)
		end) .. ({ '', '==', '=' })[#data % 3 + 1])
	end,

	---Encode a string as its base64 representation.
	---@param data string The string to encode.
	---@return string
	b64_decode = function(data)
		--[[Source: http://lua-users.org/wiki/BaseSixtyFour]]
		local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		data = string.gsub(data, '[^' .. b .. '=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r, f = '', (b:find(x) - 1)
			for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
			return r
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c = 0
			for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
			return string.char(c)
		end))
	end,

	---Filter a string so it only contains characters that match the given pattern.
	---@param text string The text to filter.
	---@param pattern string The pattern to match against.
	---@return string
	filter = function(text, pattern)
		local result, in_text = '', text
		while #in_text > 0 do
			local m = in_text:match('^' .. pattern)
			if m and (#m > 0) then
				result = result .. m
			else
				m = 'x'
			end
			in_text = in_text:sub(#m + 1, #in_text)
		end
		return result
	end,

	hash = SHA256,

	---Create an object with appropriate metatable data.
	---@return table
	object = function()
		return setmetatable({}, { is_array = false })
	end,

	---Create an array with appropriate metatable data.
	---@return table
	array = function()
		return setmetatable({}, { is_array = true })
	end,

	---Manually set whether a table is an array or an object.
	---@param tbl table The table to set the type of.
	---@param is_array boolean Whether the table is an array or not.
	set_table_type = function(tbl, is_array)
		if type(tbl) ~= 'table' then return end
		setmetatable(tbl, { is_array = is_array })
	end,

	---Swap a table's keys and values.
	---@param array table
	---@return table
	invert_array = function(array)
		local result = {}
		for key, value in pairs(array) do result[value] = key end
		return result
	end,

	---Remove any duplicate values from a table.
	---@param list table
	---@return table
	unique = function(list)
		local result = {}
		for key, value in pairs(std.invert_array(list)) do table.insert(result, key) end
		return result
	end,

	---Create the union of two sets.
	---@param list1 table
	---@param list2 table
	---@return table
	union = function(list1, list2)
		local temp = std.invert_array(list1)
		for key, value in pairs(list2) do temp[value] = true end
		local result = {}
		for key, value in pairs(temp) do table.insert(result, key) end
		return result
	end,

	---Create the intersection of two sets.
	---@param list1 table
	---@param list2 table
	---@return table
	intersection = function(list1, list2)
		local inv_l2, result = std.invert_array(list2), {}
		for key, value in pairs(list1) do
			if inv_l2[value] then
				table.insert(result, value)
			end
		end
		return result
	end,

	---Create the difference of two sets.
	---@param list1 table
	---@param list2 table
	---@return table
	difference = function(list1, list2)
		local inv_l2, result = std.invert_array(list2), {}
		for key, value in pairs(list1) do
			if not inv_l2[value] then
				table.insert(result, value)
			end
		end
		return result
	end,

	---Create the symmetric difference of two sets.
	---@param list1 table
	---@param list2 table
	---@return table
	symmetric_difference = function(list1, list2)
		local inv_l1, inv_l2, result = std.invert_array(list1), std.invert_array(list2), {}
		for key, value in pairs(list1) do
			if not inv_l2[value] then table.insert(result, value) end
		end
		for key, value in pairs(list2) do
			if not inv_l1[value] then table.insert(result, value) end
		end
		return result
	end,

	---Check if two sets are disjoint.
	---@param list1 table
	---@param list2 table
	---@return boolean
	is_disjoint = function(list1, list2)
		local inv_l2 = std.invert_array(list2)
		for key, value in pairs(list1) do
			if inv_l2[value] then return false end
		end
		return true
	end,

	---Check if the first set is a subset of the second.
	---@param list1 table
	---@param list2 table
	---@return boolean
	is_subset = function(list1, list2)
		if std.is_disjoint(list1, list2) then return false end

		local inv_l2 = std.invert_array(list2)
		for key, value in pairs(list1) do
			if not inv_l2[value] then return false end
		end
		return #list1 <= #list2
	end,

	---Check if the first set is a superset of the second.
	---@param list1 table
	---@param list2 table
	---@return boolean
	is_superset = function(list1, list2)
		if std.is_disjoint(list1, list2) then return false end

		local inv_l1 = std.invert_array(list1)
		for key, value in pairs(list2) do
			if not inv_l1[value] then return false end
		end
		return #list1 >= #list2
	end,

	---Get the sign of a number. Returns -1 if a number is negative, 0 if zero, or 1 if positive.
	---@param number number
	---@return number
	sign = function(number)
		return number / math.abs(number)
	end,

	---Convert a number to a numeric string of any base (in the range 2-36).
	---Values both before and after the decimal point are included in the output.
	---@param number number The number to convert to a numeric string.
	---@param base number The base of the number, clamped to [2,36] and rounded down.
	---@param pad_width number The minimum width of the output string.
	---@return string
	to_base = function(number, base, pad_width)
		local FRACT_DIGITS = 6
		local FRACT_MIN = 0.000001
		local negative = number < 0
		if negative then number = -number end

		base = math.min(36, math.max(2, math.floor(base)))
		pad_width = math.max(0, math.floor(pad_width))

		local result = ''
		local integral = math.floor(number)
		local fractional = number - integral

		local function to_base(digit)
			if digit > 9 then
				return string.char(87 + digit) -- 'a'
			end
			return string.char(48 + digit) -- '0'
		end

		--Generate integer part
		while integral > 0 do
			result = to_base(integral % base) .. result
			integral = math.floor(integral / base)
		end

		--Generate fractional part
		if fractional > FRACT_MIN then
			result = result .. '.'
			for i = 1, FRACT_DIGITS do
				fractional = fractional * base
				result = result .. to_base(math.floor(fractional))
				if fractional < FRACT_MIN then break end --Exit early if remaining fractional part is very small
			end
		end

		--Pad to the specified width
		if #result < pad_width then
			result = string.rep('0', pad_width - #result - (negative and 1 or 0)) .. result
		end
		return (negative and '-' or '') .. result
	end,

	---Convert a numeric string of any base (in the range 2-36) into a number.
	---Both the integer and fractional parts of the string are converted.
	---If the string contains invalid characters, 0 is returned.
	---@param text string The numeric string to convert.
	---@param base number The base of the number, clamped to [2,36] and rounded down.
	---@return number
	from_base = function(text, base)
		local negative = text:sub(1, 1) == '-'
		if negative then text = text:sub(2) end

		base = math.min(36, math.max(2, math.floor(base)))
		local radix = text:find('.', 1, true) or (#text + 1)

		local function from_base(char)
			local byte = string.byte(char)
			if byte >= 48 and byte <= 57 then
				return byte - 48 -- '0'-'9'
			elseif byte >= 65 and byte <= 90 then
				return byte - 55 -- 'A'-'Z'
			elseif byte >= 97 and byte <= 122 then
				return byte - 87 -- 'a'-'z'
			end
			return -1
		end

		local integer_part = 0
		local fractional_part = 0

		--Process integer part
		for i = 1, radix - 1 do
			local digit = from_base(text:sub(i, i))
			if digit < 0 or digit >= base then return 0 end
			integer_part = integer_part * base + digit
		end

		--Process fractional part
		local place = base
		for i = radix + 1, #text do
			local digit = from_base(text:sub(i, i))
			if digit < 0 or digit >= base then return 0 end
			fractional_part = fractional_part + digit / place
			place = place * base
		end

		return (negative and -1 or 1) * (integer_part + fractional_part)
	end,

	---@brief Check if two values are strictly equal.
	---@note This function will compare arrays and objects recursively.
	---@param data1 any
	---@param data2 any
	---@return boolean True if the values are equal, false otherwise.
	equal = function(data1, data2)
		if std.type(data1) ~= std.type(data2) then return false end

		if std.type(data1) == 'array' then
			if #data1 ~= #data2 then return false end
			for i = 1, #data1 do
				if not std.equal(data1[i], data2[i]) then return false end
			end
			return true
		elseif std.type(data1) == 'object' then
			for key, value in pairs(data1) do
				if not std.equal(data2[key], value) then return false end
			end
			for key, value in pairs(data2) do
				if not std.equal(data1[key], value) then return false end
			end
			return true
		else
			return data1 == data2
		end
	end,

	---@brief Normalize a vector to length 1.
	---@param vector number[] The vector to normalize.
	---@return number[] The normalized vector.
	normalize = function(vector)
		local length = 0
		for i = 1, #vector do
			local num = std.num(vector[i])
			length = length + num * num
		end
		length = math.sqrt(length)
		if length == 0 then return vector end

		local result = std.array()
		for i = 1, #vector do
			result[i] = std.num(vector[i]) / length
		end
		return result
	end,

	---@brief Select a random element from an array according to a distribution.
	---@param array any[]
	---@param weights number[]
	---@return any
	random_weighted = function(array, weights)
		local total = 0
		local length = math.min(#array, #weights)
		for i = 1, length do
			total = total + std.num(weights[i])
		end
		local rand = math.random() * total
		local cumulative = 0
		for i = 1, length do
			cumulative = cumulative + std.num(weights[i])
			if rand < cumulative then
				return array[i]
			end
		end

		return array[length]
	end,

	---@brief Group elements of an array into sub-arrays of a given size.
	---@param array any[]
	---@param size integer
	---@return any[][]
	chunk = function(array, size)
		if size < 1 then return std.array() end

		local result = std.array()
		local chunk = std.array()
		for i = 1, #array do
			table.insert(chunk, array[i])
			if #chunk == size then
				table.insert(result, chunk)
				chunk = std.array()
			end
		end
		if #chunk > 0 then table.insert(result, chunk) end
		return result
	end,

	---@brief Update an element in a nested array or object structure.
	---@param data any The array, object, or string to update.
	---@param indices any|any[] The index or list of indices to navigate to the element to update.
	---@param value any The new value to set at the specified location.
	---@return any The updated array, object, or string. If the specified indices do not lead to a valid location, the original data is returned unchanged.
	---@warning This function modifies `data` in place! It does not create a copy.
	update_element = function(data, indices, value)
		local is_string = false

		--Only valid for arrays, objects, or strings
		if type(data) == 'string' then
			is_string = true
			data = std.split(data, '')
		elseif type(data) ~= 'table' then
			return data
		end

		if type(indices) ~= 'table' then indices = { indices } end
		if #indices == 0 then
			return data
		end

		--Narrow down to sub-object
		local sub_object = data
		for i = 1, #indices - 1 do
			local ix, tp = indices[i], std.type(sub_object)
			if tp == 'object' then
				ix = std.str(ix)
			elseif tp ~= 'array' then
				return data
			else
				ix = std.num(ix)
				if ix < 0 then ix = #sub_object + ix + 1 end
			end

			if sub_object[ix] == nil then
				--We can only set the bottom-level object
				return data
			end

			sub_object = sub_object[ix]
		end

		local ix, tp = indices[#indices], std.type(sub_object)
		if tp == 'object' then
			ix = std.str(ix)
			sub_object[ix] = value
		elseif tp == 'array' then
			ix = std.num(ix)
			if ix < 0 then ix = #sub_object + ix + 1 end
			if ix > 0 then
				sub_object[ix] = value
			else
				table.insert(sub_object, 1, value)
			end
		end

		if is_string then
			data = std.join(data, '')
		end

		return data
	end,

	---@brief Escape XML entities.
	---@param text string The original text.
	---@return string escaped_text The text with XML entities escaped.
	--[[minify-delete]]
	escape_xml = function(text)
		local fmt = {
			{ '&',  '&amp;' },
			{ '"',  '&quot;' },
			{ '\'', '&apos;' },
			{ '<',  '&lt;' },
			{ '>',  '&gt;' },
		}
		for _, i in ipairs(fmt) do
			text = text:gsub(i[1], i[2])
		end
		return text
	end,
	--[[/minify-delete]]

	MAX_ARRAY_LEN = 32768, --Any larger than this and performance tanks

	--Perform bitwise and/or/xor
	_bitwise = function(a, b, oper)
		local u32 = 2 ^ 32

		local function lo(x)
			return x % u32
		end

		local function hi(x)
			--In some versions of Lua, 64-bit integers wrap around when divided,
			--which is not what we want, so mod the result to just get the top 32 bits.
			return math.floor(x / u32) % u32
		end

		local function f(a, b, oper)
			local r, m, s = 0, 2 ^ 31, nil
			repeat
				s, a, b = a + b + m, a % m, b % m
				r, m = r + m * oper % (s - a - b), m / 2
			until m < 1
			return math.floor(r)
		end

		return math.floor(
			f(hi(a), hi(b), oper) * u32 +
			f(lo(a), lo(b), oper)
		)
	end,

	bitwise = {
		['not'] = function(value)
			return -math.floor(value) - 1
		end,

		['and'] = function(lhs, rhs)
			return std._bitwise(lhs, rhs, 4)
		end,

		['or'] = function(lhs, rhs)
			return std._bitwise(lhs, rhs, 1)
		end,

		['xor'] = function(lhs, rhs)
			return std._bitwise(lhs, rhs, 3)
		end,
	},
}
