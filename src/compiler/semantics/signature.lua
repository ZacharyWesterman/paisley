require 'src.shared.json'

local function _type_text(type_signature, func_name, position --[[minify-delete]], colorize --[[minify-delete]])
	if not type_signature then return 'any' end

	local types = {}
	for j, k in ipairs(type_signature) do
		---@diagnostic disable-next-line
		local key = TYPE_TEXT(k[((position or 1) - 1) % #k + 1] --[[minify-delete]], colorize --[[minify-delete]])
		if key and std.arrfind(types, key, 1) == 0 then table.insert(types, key) end
	end
	if func_name == 'reduce' and position == 2 then types[1] = 'operator' end
	return std.join(types, '|')
end

--Helper func for generating func_call error messages.
return function(func_name --[[minify-delete]], colorize --[[minify-delete]])
	local param_ct = BUILTIN_FUNCS[func_name]
	local params = ''
	if param_ct == -1 then
		local arg_name = '...'
		--[[minify-delete]]
		if colorize then
			local vscode = require "src.util.vscode"
			arg_name = '**' .. vscode.color(' ... ', vscode.theme.var) .. '**'
		end
		--[[/minify-delete]]
		params = arg_name .. ': ' ..
			_type_text(TYPESIG[func_name].valid, func_name --[[minify-delete]], nil, colorize --[[/minify-delete]])
	elseif param_ct ~= 0 then
		for i = 1, math.abs(param_ct) do
			--[[minify-delete]]
			if TYPESIG[func_name].params and TYPESIG[func_name].params[i] then
				if colorize then
					local vscode = require "src.util.vscode"
					params = params .. vscode.color(TYPESIG[func_name].params[i], vscode.theme.var)
				else
					params = params .. TYPESIG[func_name].params[i]
				end
			else
				--[[/minify-delete]]
				params = params .. string.char(96 + i)
				--[[minify-delete]]
			end
			params = params .. ': ' .. _type_text(TYPESIG[func_name].valid, func_name, i, colorize)
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
