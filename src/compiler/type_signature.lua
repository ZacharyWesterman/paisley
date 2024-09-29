---Generate a type signature object allow easy comparison of complex types.
---The following types are valid:
---array       object
---string      number
---boolean     null
---any
---
---For values that may be any of multiple types, you can separate the types with a bar,
---e.g. "string|number". Or you may use "any" to indicate that the result could be anything.
---To indicate that a type is optional, you may add a "?" to the type, e.g. "string?".
---This is equivalent to "string|null".
---
---Arrays and objects may have an optional subtype, e.g. "array[number]". if not specified,
---this subtype will default to "any".
--- 
---@param signature string A type signature string representation.
---@return table TypeSignature A table representing a type signature. This should not be manipulated directly, instead use the functions in this file.
function SIGNATURE(signature)
	local patterns = {'^%w+', '^|', '^%[', '^%]', '?'}
	local typenames = {any = true, object = true, array = true, string = true, number = true, boolean = true, null = true,}
	local tokens = {}
	local sig = signature
	local bracket_ct = 0

	local function do_error(message, char)
		error(message .. ' in type signature "'..signature..'" at char '..char)
	end

	--Split signature into valid tokens
	while #sig > 0 do
		--Ignore spaces
		if sig:sub(1,1) == ' ' then
			sig = sig:sub(2, #sig)
		end

		local m = nil
		for i = 1, #patterns do
			m = sig:match(patterns[i])
			if m then
				if i == 1 and not typenames[m] then
					do_error('Invalid type "'..m..'"', #signature - #sig)
				elseif i == 3 then
					bracket_ct = bracket_ct + 1
				elseif i == 4 then
					bracket_ct = bracket_ct - 1
					if bracket_ct < 0 then
						do_error('Bracket mismatch', #signature - #sig)
					end
				end
				
				sig = sig:sub(#m + 1, #sig)

				if i == 5 then
					--Equate "?" operator to mean "|null".
					table.insert(tokens, {text = '|', kind = 2}) --Insert bar
					m, i = 'null', 1 --Change type to "null"
				end

				table.insert(tokens, {text = m, kind = i})
				break
			end
		end

		if not m then
			do_error('Invalid character', #signature - #sig)
		end
	end
	if bracket_ct > 0 then
		do_error('Bracket mismatch', #signature - #sig)
	end

	--Parse signature into a valid type tree
	local function do_error(message)
		error(message .. ' in type signature "'..signature..'"')
	end
	local function ast(index)
		local opt, i, exp_delim, subtypes, found = {}, index, false, nil, {}

		while i > 0 do
			local t = tokens[i]
			if t.kind == 2 then
				if not exp_delim then
					do_error('Unexpected bar')
				end
				exp_delim = false
			else
				if exp_delim and t.kind ~= 3 then
					do_error('Missing bar')
				end

				if t.kind == 1 then
					if t.text == 'object' or t.text == 'array' then
						if not subtypes then subtypes = {any = {type = 'any'}} end
					elseif subtypes then
						do_error('Type "'..t.text..'" cannot have a subtype')
					end

					if opt[t.text] then
						do_error('Redundant use of type "'..t.text..'"')
					elseif opt.any then
						do_error('Cannot mix "any" with other types')
					end

					exp_delim = true
					opt[t.text] = {
						type = t.text,
						subtypes = subtypes,
					}
					subtypes = nil
				elseif t.kind == 4 then
					subtypes, i = ast(i - 1)
				elseif t.kind == 3 then
					if found.any and #opt > 1 then
						do_error('Cannot mix "any" with other types')
					end
					return opt, i
				end
			end
		
			i = i - 1
		end

		return opt
	end

	return ast(#tokens)
end

_G['TYPE_ANY'] = SIGNATURE('any')
_G['TYPE_OBJECT'] = SIGNATURE('object')
_G['TYPE_ARRAY'] = SIGNATURE('array')
_G['TYPE_STRING'] = SIGNATURE('string')
_G['TYPE_NUMBER'] = SIGNATURE('number')
_G['TYPE_BOOLEAN'] = SIGNATURE('boolean')
_G['TYPE_NULL'] = SIGNATURE('null')

_G['TYPE_ARRAY_STRING'] = SIGNATURE('array[string]')

---Check if two type signatures can match up.
---E.g. "any" and "string" are similar enough, "number|string" and "string" are similar enough, etc.
---@param lhs table The first type signature to compare.
---@param rhs table The second type signature to compare.
---@return boolean is_similar True if the have any subtypes that match, false otherwise.
function SIMILAR_TYPE(lhs, rhs)
	if lhs.any or rhs.any then return true end

	for key, val in pairs(lhs) do
		if rhs[key] then
			if not val.subtypes then
				return true
			elseif SIMILAR_TYPE(val.subtypes, rhs[key].subtypes) then
				return true
			end
		end
	end

	return false
end

---Convert a type signature back into its string representation.
---This is useful for error reporting and debug purposes.
---@param tp table A type signature object.
---@return string signature A type signature string representation.
function TYPE_TEXT(tp)
	local result = ''
	for key, val in pairs(tp) do
		if #result > 0 then result = result .. '|' end
		result = result .. key
		if val.subtypes then
			result = result..'['..TYPE_TEXT(val.subtypes)..']'
		end
	end
	return result
end

--[[minify-delete]]
function PRINT_TYPESIG(ast, indent)
	for _, val in pairs(ast) do
		print(indent .. val.type)
		if val.subtypes then
			PRINT_TYPESIG(val.subtypes, indent .. '  ')
		end
	end
end
--[[/minify-delete]]