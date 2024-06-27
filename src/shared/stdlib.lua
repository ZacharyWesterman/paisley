--This is a "standard library" of sorts, containing code that's shared between the Paisley compiler and runtime engine.

require "src.shared.hash"

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
			return '"'..data..'"'
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
	---@param items any[]
	---@param delimiter string
	---@return string
	join = function(items, delimiter)
		local result = ''
		for i = 1, #items do
			if i > 1 then result = result .. delimiter end
			result = result .. std.str(items[i])
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
			for i = 2, #data do
				local subtp = std.deep_type(data[i])

				--Array contains multiple types; cannot deduce a single sub-type.
				if subtp ~= subtype then return 'array' end
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
		local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		return ((data:gsub('.', function(x)
			local r,b='',x:byte()
			for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
			return r
		end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c=0
			for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
			return b:sub(c+1,c+1)
		end)..({ '', '==', '=' })[#data%3+1])
	end,

	---Encode a string as its base64 representation.
	---@param data string The string to encode.
	---@return string
	b64_decode = function(data)
		--[[Source: http://lua-users.org/wiki/BaseSixtyFour]]
		local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		data = string.gsub(data, '[^'..b..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',(b:find(x)-1)
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
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
			local m = in_text:match('^'..pattern)
			if m and (#m > 0) then
				result = result .. m
			else
				m = 'x'
			end
			in_text = in_text:sub(#m+1, #in_text)
		end
		return result
	end,

	hash = SHA256,

	---Create an object with appropriate metatable data.
	---@return table
	object = function()
		return setmetatable({}, {is_array = false})
	end,

	---Create an array with appropriate metatable data.
	---@return table
	array = function()
		return setmetatable({}, {is_array = true})
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

	MAX_ARRAY_LEN = 32768, --Any larger than this and performance tanks
}
