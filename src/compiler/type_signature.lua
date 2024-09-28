---Generate a type signature object allow easy comparison of complex types.
---@warning The Plasma build of this does not check for valid syntax.
---@param signature any
function SIGNATURE(signature)
	local patterns = {'^%w+', '^|', '^%[', '^%]'}
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
				if i == 3 then
					bracket_ct = bracket_ct + 1
				elseif i == 4 then
					bracket_ct = bracket_ct - 1
					--[[minify-delete]]
					if bracket_ct < 0 then
						do_error('Bracket mismatch', #signature - #sig)
					end
				elseif i == 1 and not typenames[m] then
					do_error('Invalid type "'..m..'"', #signature - #sig)
					--[[/minify-delete]]
				end 

				table.insert(tokens, {text = m, kind = i})
				sig = sig:sub(#m + 1, #sig)
				break
			end
		end

		--[[minify-delete]]
		if not m then
			do_error('Invalid character', #signature - #sig)
		end
		--[[/minify-delete]]
	end
	--[[minify-delete]]
	if bracket_ct > 0 then
		do_error('Bracket mismatch', #signature - #sig)
	end
	--[[/minify-delete]]

	--Parse signature into a valid type tree
	--[[minify-delete]]
	local function do_error(message)
		error(message .. ' in type signature "'..signature..'"')
	end
	--[[/minify-delete]]
	local function ast(index)
		local opt, i, exp_delim, subtypes, found = {}, index, false, nil, {}

		while i > 0 do
			local t = tokens[i]
			if t.kind == 2 then
				--[[minify-delete]]
				if not exp_delim then
					do_error('Unexpected bar')
				end
				--[[/minify-delete]]
				exp_delim = false
			else
				--[[minify-delete]]
				if exp_delim and t.kind ~= 3 then
					do_error('Missing bar')
				end
				--[[/minify-delete]]

				if t.kind == 1 then
					if t.text == 'object' or t.text == 'array' then
						if not subtypes then subtypes = {any = {type = 'any'}} end
					--[[minify-delete]]
					elseif subtypes then
						do_error('Type "'..t.text..'" cannot have a subtype')
					--[[/minify-delete]]
					end

					--[[minify-delete]]
					if opt[t.text] then
						do_error('Redundant use of type "'..t.text..'"')
					elseif opt.any then
						do_error('Cannot mix "any" with other types')
					end
					--[[/minify-delete]]

					exp_delim = true
					opt[t.text] = {
						type = t.text,
						subtypes = subtypes,
					}
					subtypes = nil
				elseif t.kind == 4 then
					subtypes, i = ast(i - 1)
				elseif t.kind == 3 then
					--[[minify-delete]]
					if found.any and #opt > 1 then
						do_error('Cannot mix "any" with other types')
					end
					--[[/minify-delete]]
					return opt, i
				end
			end
		
			i = i - 1
		end

		return opt
	end

	return ast(#tokens)
end

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
