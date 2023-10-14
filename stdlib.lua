--This is a "standard library" of sorts, containing code that's shared between the Paisley compiler and runtime engine.

std = {
	--Convert arbitrary data to a string (with "Lua-ness" removed)
	str = function(data --[[any]])
		if data == nil then return '' end
		if data == true then return '1' end
		if data == false then return '0' end

		if type(data) == 'table' then
			local result, i = ''
			local first = true
			for i = 1, #data do
				if not first then result = result .. ' ' end
				result = result .. std.str(data[i])
				first = false
			end
			return result
		end
		return tostring(data)
	end,

	debug_str = function(data)
		if type(data) == 'table' then
			local result = ''
			local key, value
			local first = true
			for key, value in pairs(data) do
				if not first then result = result .. ',' end
				result = result .. std.debug_str(value)
				first = false
			end
			return '{' .. result .. '}'
		elseif type(data) == 'string' then
			return '"'..data..'"'
		else
			return std.str(data)
		end
	end,

	--Cast data to a boolean
	bool = function(data --[[any]])
		return not data or data == 0 or data == '' or (type(data) == 'table' and #data == 0)
	end,

	--Cast data to a number
	num = function(data --[[any]])
		if data == true then return 1 end
		local val = tonumber(data)
		if val == nil then return 0 else return val end
	end,

	--Join an array of items into a string
	join = function(items --[[table]], delimiter --[[string]])
		local result, i = ''
		for i = 1, #items do
			if i > 1 then result = result .. delimiter end
			result = result .. std.str(items[i])
		end
		return result
	end,

	--Get the type of some data, with the "Lua-ness" removed
	type = function(data --[[any]])
		if data == nil then return 'null' end
		if type(data) == 'table' then return 'array' end
		return type(data)
	end,

	--Split a string by delimiter
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

	contains = function(text, substring)
		local i
		for i = 1, #text - #substring + 1 do
			if text:sub(i, i + #substring - 1) == substring then
				return true
			end
		end
		return false
	end,

}