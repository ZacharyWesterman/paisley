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
				end
			elseif ar:sub(1, 1) == '-' then
				local is_prefix = false
				for prefix, option in pairs(prefixes) do
					if ar:sub(1, #prefix) == prefix then
						if option.type then
							local text = ar:sub(#prefix + 1)
							if text == "" then
								ARG.error("Expected argument for flag `" .. prefix .. "`")
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

		if hold_arg then ARG.error("Expected argument for flag `" .. hold_arg .. "`") end

		return flag_args, positional_args
	end
}
