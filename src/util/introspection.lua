local log = require 'src.log'

INTROSPECT = {
	text_table = function(data)
		local widths, text = {}, ''

		--Calculate the width of each column
		for i, row in ipairs(data) do
			for k, cell in ipairs(row) do
				if widths[k] == nil then widths[k] = 0 end
				widths[k] = math.max(widths[k], #std.str(cell))
			end
		end

		local function delim()
			local text = '+'
			for i = 1, #widths do
				text = text .. ('-'):rep(widths[i] + 2) .. '+'
			end

			return text
		end

		--Generate text
		for i = 1, #data do
			if i > 2 then text = text .. '|' else text = text .. delim() .. '\n|' end
			for k = 1, #data[i] do
				text = text .. ' ' .. std.str(data[i][k]) .. (' '):rep(widths[k] - #std.str(data[i][k])) .. ' |'
			end
			text = text .. '\n'
		end
		text = text .. delim()

		return text
	end,

	commands = function(cmd_list)
		ALLOWED_COMMANDS = V3 or {}
		require 'src.shared.stdlib'
		require 'src.compiler.type_signature'
		require 'src.shared.builtin_commands'

		if cmd_list then
			--List detailed info about the commands
			for i = 1, #cmd_list do
				local key = cmd_list[i]
				if key == 'ALL' then
					cmd_list = {}
					for k, v in pairs(BUILTIN_COMMANDS) do table.insert(cmd_list, k) end
					for k, v in pairs(ALLOWED_COMMANDS) do table.insert(cmd_list, k) end
					break
				end
				if not BUILTIN_COMMANDS[key] and not ALLOWED_COMMANDS[key] then
					log.error('`' .. key .. '` is not a built-in or user-defined command.')
					os.exit(1)
				end
			end

			for i = 1, #cmd_list do
				local key = cmd_list[i]
				print(key .. ' -> ' .. TYPE_TEXT(BUILTIN_COMMANDS[key] or ALLOWED_COMMANDS[key]))
				print('    ' .. (CMD_DESCRIPTION[key] or 'User-defined command.'))
				print()
			end
		else
			--Just list the commands
			for key, val in pairs(BUILTIN_COMMANDS) do
				print(key)
			end
			for key, val in pairs(ALLOWED_COMMANDS) do
				print(key)
			end
		end
	end,

	functions = function(func_list, show_synonyms)
		ALLOWED_COMMANDS = V3 or {}
		require 'src.shared.stdlib'
		require 'src.compiler.type_signature'
		require 'src.compiler.tokens'
		require 'src.compiler.semantics'
		local FUNCSIG = require "src.compiler.semantics.signature"
		local synonyms = require 'src.compiler.semantics.synonyms'
		synonyms.reduce = true

		local funcs = {}
		for key, _ in pairs(BUILTIN_FUNCS) do table.insert(funcs, key) end
		table.sort(funcs)

		if func_list then
			--List detailed info about the functions
			for i = 1, #func_list do
				local key = func_list[i]
				if key == 'ALL' then
					func_list = funcs
					break
				end

				if not BUILTIN_FUNCS[key] then
					log.error('`' .. key .. '` is not a built-in function.')
					os.exit(1)
				end
			end

			for i = 1, #func_list do
				local key = func_list[i]
				local funcsig = key .. '(' .. FUNCSIG(key) .. ') -> '
				if TYPESIG[key].out == 1 then
					--Return type is the same as 1st param
					local types = {}
					for i, k in ipairs(TYPESIG[key].valid) do
						table.insert(types, k[1])
					end
					funcsig = funcsig .. std.join(types, '|', TYPE_TEXT)
				else
					funcsig = funcsig .. TYPE_TEXT(TYPESIG[key].out)
				end

				if show_synonyms == nil or (show_synonyms == (synonyms[key] ~= nil)) then
					print(funcsig)
					print('    ' .. TYPESIG[key].description)
					print()
				end
			end
		else
			--Just list the functions
			for i = 1, #funcs do
				if show_synonyms == nil or (show_synonyms == (synonyms[funcs[i]] ~= nil)) then
					print(funcs[i])
				end
			end
		end
	end,
}
