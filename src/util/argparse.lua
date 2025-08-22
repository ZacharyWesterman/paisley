require 'src.util.filesystem'

ARG = {
	error = function(msg)
		io.stderr:write("Error: " .. msg .. "\n")
		os.exit(1)
	end,

	help = function(options, config)
		local function print_option(option)
			local str = ""
			if option.short then
				str = str .. "-" .. option.short
				if option.arg then str = str .. option.arg end
			end
			if option.short and option.long then str = str .. ", " end
			if option.long then
				str = str .. "--" .. option.long
				if option.arg then str = str .. "=" .. option.arg end
			end
			return str
		end

		local max_len = 0
		for _, option in ipairs(options) do
			if not option.name or option.composite then
				local len = #print_option(option)
				if len > max_len then max_len = len end
			end
		end

		io.write(config.name .. " " .. config.version .. "\n\n")
		io.write(config.description .. "\n\n")
		io.write("Usage: " .. config.exe .. " [FLAGS]")
		for _, option in ipairs(options) do
			if option.name and not option.composite then
				io.write(" <" .. option.name .. ">")
			end
		end
		io.write("\n\nFLAGS:\n")
		for _, option in ipairs(options) do
			if not option.name or option.composite then
				local text = print_option(option)
				io.write("  " .. text .. string.rep(" ", max_len - #text + 1) .. option.description .. "\n")
			end
		end

		io.write("\n")
		io.write("ARGS:\n")
		for _, option in ipairs(options) do
			if option.name and not option.composite then
				io.write("  <" ..
					option.name .. ">" .. string.rep(" ", max_len - #option.name - 1) .. option.description .. "\n")
			end
		end

		os.exit(0)
	end,

	parse = function(options)
		local prefixes = {}
		local short = {}
		local long_no_arg = {}
		local long_with_arg = {}

		for _, option in ipairs(options) do
			local id = (option.name or option.long or option.short):gsub('-', '_')
			option.id = id

			if option.composite then
				if option.short then prefixes['-' .. option.short] = option end
				if option.long then prefixes['--' .. option.long] = option end
			end

			if option.short then short[option.short] = option end
			if option.long then
				if option.type then
					long_with_arg['--' .. option.long] = option
				else
					long_no_arg['--' .. option.long] = option
				end
			end
		end

		--Parse arguments
		local flag_args = {}
		local positional_args = {}

		local no_more_flags = false
		local hold_arg = nil
		for i = 1, #arg do
			local ar = arg[i]

			if hold_arg then
				flag_args[hold_arg] = ar
				hold_arg = nil
			elseif no_more_flags then
				table.insert(positional_args, ar)
			elseif ar == "--" then
				no_more_flags = true
			elseif ar:sub(1, 2) == "--" then
				if long_no_arg[ar] then
					local option = long_no_arg[ar]
					flag_args[option.id] = true
				elseif long_with_arg[ar] then
					local option = long_with_arg[ar]
					if not option then ARG.error("Unknown flag `" .. ar .. "`") end
					hold_arg = option.id
				elseif ar:match('=') then
					local option = long_with_arg[ar:match('^[^=]*')]
					if not option then ARG.error("Unknown flag `" .. ar .. "`") end
					flag_args[option.id] = ar:match('=.*$'):sub(2)
				else
					ARG.error("Unknown flag `" .. ar .. "`")
				end
			elseif ar:sub(1, 1) == '-' and ar ~= '-' then
				local is_prefix = false
				for prefix, option in pairs(prefixes) do
					if ar:sub(1, #prefix) == prefix then
						if option.type then
							local text = ar:sub(#prefix + 1)
							if text == "" then
								local msg = "Expected argument for flag `" .. prefix .. "`"
								if option.options then
									msg = msg ..
										" (can be one of `" .. table.concat(option.options, '`, `') .. '`)'
								end
								ARG.error(msg)
							end

							if option.type == 'array' then
								if not flag_args[option.id] then
									flag_args[option.id] = {}
								end
								table.insert(flag_args[option.id], text)
							else
								flag_args[option.id] = text
							end
						else
							flag_args[option.id] = true
						end
						is_prefix = true
						break
					end
				end

				if not is_prefix then
					for i = 2, #ar do
						local c = ar:sub(i, i)
						if short[c] then
							local option = short[c]
							if option.type then
								hold_arg = option.id
							else
								flag_args[option.id] = true
							end
						else
							ARG.error("Unknown flag `-" .. c .. "`")
						end
					end
				end
			else
				table.insert(positional_args, ar)
			end
		end

		if hold_arg then
			local msg = "Expected argument for flag `" .. hold_arg .. "`"
			local option = long_with_arg['--' .. hold_arg:gsub('_', '-')]
			if option and option.options then
				msg = msg ..
					" (can be one of `" .. table.concat(option.options, '`, `') .. '`)'
			end
			ARG.error(msg)
		end

		--Make sure any flag args that have an array of options were actually given a valid option.
		for _, option in pairs(long_with_arg) do
			if option.options and flag_args[option.id] then
				local valid = false
				for _, v in ipairs(option.options) do
					if v == flag_args[option.id] then
						valid = true
						break
					end
				end

				if not valid then
					local msg = "Invalid option `" .. flag_args[option.id] .. "` for flag `--" .. option.long .. "`"
					msg = msg .. " (can be one of `" .. table.concat(option.options, '`, `') .. '`)'
					ARG.error(msg)
				end
			end
		end

		return flag_args, positional_args
	end,

	--This is specific to the Paisley application. The logic is not generic.
	parse_and_validate = function(options, config)
		local flags, positional = ARG.parse(options)

		if flags.help then
			ARG.help(options, config)
			os.exit(0)
		end

		if flags.version then
			io.write(config.version .. "\n")
			os.exit(0)
		end

		if flags.rocks then
			io.stderr:write('For best results, install the following Lua rocks:\n')

			local text = --[[build-replace=requires.txt]] FS.open('requires.txt', true):read('*all') --[[/build-replace]]
			local args = ''
			for l in text:gmatch('[^\n]+') do
				local i = l:match('^[^ ]+')
				print(i)
				args = args .. ' ' .. i
			end

			io.stderr:write('\nNone of these are required for the Paisley compiler to work,\n')
			io.stderr:write('but some extra features will be disabled if they\'re not installed.\n')
			io.stderr:write('\nYou can use the following command to install them all:\n')
			io.stderr:write('  luarocks install' .. args .. '\n')
			io.stderr:write('Or, if you\'re on Linux, you can just run `./install.sh`\n')
			os.exit(0)
		end

		--[[no-install]]
		if flags.compile_self then
			if flags.install then
				ARG.error('Cannot use `--compile-self` and `--install` together; it must be one or the other.')
			end

			if not flags.output then
				ARG.error('Must specify an output file with `--output` when using `--compile-self`.')
			end

			return flags, positional
		end
		--[[/no-install]]

		if (flags.standalone or flags.target or flags.output) and flags.cpp_precompile then
			ARG.error(
				'The `--cpp-precompile` flag should be used either by itself or with `--cpp-clean`, to pre-compile the C++ run-time.')
		end

		if (flags.standalone or flags.target or flags.output) and not flags.cpp_precompile and flags.cpp_clean then
			ARG.error(
				'The `--cpp-clean` flag should be used either by itself or with `--cpp-precompile`, to remove precompiled C++ object files.')
		end

		if flags.introspect or flags.repl --[[no-install]] or flags.install --[[/no-install]] or flags.plasma_build or flags.cpp_precompile or flags.cpp_clean then
			return flags, positional
		end

		if not flags.introspect and (flags.introspect_func or flags.introspect_cmds or flags.functions or flags.commands) then
			ARG.error('Introspection flags can only be used with `--introspect`.')
		end

		if not flags.standalone and flags.target then
			ARG.error('The `--target` flag doesn\'t make sense without `--standalone`.')
		end

		if #positional < 1 then
			ARG.error(
				'No input file given. Use `-` to read from stdin, or re-run with `--help` to see all options.'
			)
		end

		if flags.sandbox then flags.shell = false end

		if flags.bytecode and flags.output then
			ARG.error(
				'`--output` implicitly converts to bytecode when writing (unless otherwise specified), so `--bytecode` is not needed.'
			)
		end

		return flags, positional
	end,

	print = function(flags, positional)
		io.write("Flags:\n")
		for k, v in pairs(flags) do
			if type(v) == 'table' then
				io.write("  " .. k .. ": {" .. table.concat(v, ', ') .. "}\n")
			else
				io.write("  " .. k .. ": " .. tostring(v) .. "\n")
			end
		end

		io.write("\nPositional:\n")
		for _, v in ipairs(positional) do
			io.write("  " .. v .. "\n")
		end
	end
}
