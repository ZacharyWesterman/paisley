--Helper func for generating func_call error messages.
return function(func_name)
	local param_ct = BUILTIN_FUNCS[func_name]
	local params = ''
	if param_ct == -1 then
		params = '...'
	elseif param_ct ~= 0 then
		for i = 1, math.abs(param_ct) do
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
					---@diagnostic disable-next-line
					local key = TYPE_TEXT(k[(i - 1) % #k + 1])
					if key and std.arrfind(types, key, 1) == 0 then table.insert(types, key) end
				end
			else
				table.insert(types, 'any')
			end
			if func_name == 'reduce' and i == 2 then types[1] = 'operator' end
			params = params .. ': ' .. std.join(types, '|')
			--[[/minify-delete]]

			--Indicate that some parameters are optional.
			if param_ct < 0 and i == 1 then params = params .. ' [' end

			if i < math.abs(param_ct) then params = params .. ',' end
			--[[minify-delete]]
			if i < math.abs(param_ct) then params = params .. ' ' end
			--[[/minify-delete]]

			if param_ct < 0 and i == math.abs(param_ct) then params = params .. ']' end
		end
	end
	return params
end
