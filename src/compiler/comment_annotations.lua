--[[minify-delete]]
EXPORT_LINES = {}
ELIDE_LINES = {}
local NEXT_TAGS = {}
DEBUG_FUNCS = {}
local in_debug = nil

local function get_tags()
	return NEXT_TAGS
end

local function wipe_tags()
	NEXT_TAGS = {}
end

---Some comments can give hints about what commands exist, and suppress "unknown command" errors.
---Process these annotations.
---@param text string The comment text to process, including the leading # character.
---@param line number The current line number in this file.
---@param file string? The name of the current file.
local function process_comment_annotations(text, line, file)
	local _, line_ct = text:gsub('\n', '\n')

	-- Forget annotations if there's a blank line of non-comment space
	if NEXT_TAGS.line and NEXT_TAGS.line + 1 < line then
		NEXT_TAGS = {}
	end

	NEXT_TAGS.mark = true
	NEXT_TAGS.line = line + line_ct

	local function process_text(text, brief)
		text = text:gsub('#%[%[', ''):gsub('#%]%]', ''):gsub('^#', '')
		if brief then text = text:gsub('@[bB][rR][iI][eE][fF][ \t]*', '') end
		return text
	end

	local function append_text(text, brief)
		local result = NEXT_TAGS.text and (NEXT_TAGS.text .. '\n') or ''
		result = result .. process_text(text, brief)
		NEXT_TAGS.text = result
	end

	local ln = line

	local function debug_annotations(line, imported)
		if not in_debug then return end

		local index = line:find('@[eE][nN][dD]')
		if not index and not imported then
			in_debug.text = in_debug.text .. '\n' .. line
			return
		end

		--Generate function in chunk
		--Make sure anything that gives access to files is disabled.
		--(don't want comments to be able to mess with the host OS!)
		local debug_text = 'local io, os, require\n_G = {}\n'
		if not imported then
			debug_text = debug_text .. 'return function ' ..
				in_debug.text .. line:sub(1, index - 1) .. '\nend'
		else
			debug_text = debug_text .. in_debug.text
		end

		--Compile Lua text into function.
		local switch = false
		local function loadfn()
			if switch then return nil end
			switch = true
			return debug_text
		end
		local fn, error_msg = load(loadfn)

		if fn then
			local body = fn()
			if type(body) == 'function' then
				local chunk = {
					fn = body,
					span = in_debug.span,
					file = file,
				}

				--If it has a name, apply to command invocations.
				--If no name, apply the debug logic to the next user-defined function.
				if in_debug.name then
					DEBUG_FUNCS[in_debug.name] = chunk
				else
					NEXT_TAGS.debug = chunk
				end
			else
				parse_info(
					in_debug.span,
					'COMPILER BUG: Expected @debug annotation to return `function`, but got `' .. type(body) .. '`!',
					file
				)
			end
		else
			parse_info(in_debug.span, 'Syntax error in @debug annotation: ' .. error_msg, file)
		end

		in_debug = nil
	end

	-- Handle annotations like `@debug {filename}`
	local function imported_annotation(line)
		local pattern = '@[dD][eE][bB][uU][gG]%s*%{([^%}]*)%}?'
		local filename = line:gmatch(pattern)()
		if not filename then return false end

		local span = Span:new(
			NEXT_TAGS.line - line_ct, 0,
			NEXT_TAGS.line, 9999
		)

		--Use stdlib as a fallback if local file doesn't exist.
		local fs = require 'src.util.filesystem'
		local std_fp, stdlib_filename = fs.stdlib(filename, '.lua')

		--Normalize filename, relative to the current parsed file
		local current_script_dir = file and file:match('(.-)([^\\/]-%.?([^%.\\/]*))$') or './'
		filename = current_script_dir .. filename:gsub('%.', '/') .. '.lua'

		local fp = io.open(filename, 'r')
		if not fp and std_fp then
			fp = std_fp
			filename = stdlib_filename
		end

		if not fp then
			parse_info(span, 'Unable to import debug annotation from `' .. filename .. '`: file not readable.', file)
			return true
		end

		local lua_chunk = fp:read('a')
		if not lua_chunk then
			parse_info(span, 'Failed to read debug annotation from `' .. filename .. '`: file not readable.', file)
			return true
		end

		in_debug = {
			text = lua_chunk,
			span = span,
		}

		debug_annotations(line, true)

		return true
	end

	-- Handle annotations like `@debug ...(args..) ... @end`
	local function inline_annotation(line)
		local pattern = '@[dD][eE][bB][uU][gG]%s+([^%s%(]+)'
		local cmdname = line:gmatch(pattern)()
		local paren_index = line:find('%(')
		if paren_index then
			in_debug = {
				name = cmdname,
				text = line:sub(paren_index),
				span = Span:new(
					NEXT_TAGS.line - line_ct, 0,
					NEXT_TAGS.line - 1, 9999
				)
			}
		end
	end

	local function handle_annotations(i, line)
		if i == '@COMMANDS' then
			local msg = line:match('@[cC][oO][mM][mM][aA][nN][dD][sS][^%w_]([^\n]*)')
			if msg then
				for k in msg:gmatch('[%w_:]+') do
					local cmd = std.split(k, ':')
					if cmd[1] ~= '' then
						if cmd[2] == '' or not cmd[2] then cmd[2] = 'any' end
						ALLOWED_COMMANDS[cmd[1]] = SIGNATURE(cmd[2], true)
					end
				end
			end
		elseif i == '@SHELL' then
			--Allow unknown commands to coerce to shell exec
			COERCE_SHELL_CMDS = true
		elseif i == '@PLASMA' then
			--Allow script to specify that it's meant for the Plasma build
			PLASMA_RESTRICT()
			FUNC_SANDBOX_RESTRICT()
		elseif i == '@SANDBOX' then
			--Allow script to specify that no file system access is allowed
			SHELL_RESTRICT()
			FUNC_SANDBOX_RESTRICT()
		elseif i == '@EXPORT' then
			NEXT_TAGS.export = true
		elseif i == '@ALLOW_ELISION' then
			NEXT_TAGS.elide = true
		elseif i == '@PRIVATE' then
			NEXT_TAGS.private = true
		elseif i == '@BRIEF' then
			append_text(line, true)
			local brief_text = process_text(line, true)
			if NEXT_TAGS.brief then
				NEXT_TAGS.brief = NEXT_TAGS.brief .. '\n' .. brief_text
			else
				NEXT_TAGS.brief = brief_text
			end
		elseif i == '@PARAM' then
			local t = line:match('@[pP][aA][rR][aA][mM]%s*(.*%S)')
			if t then
				local name, type, desc

				name = t:match('^%S*')
				if name then
					t = t:sub(#name + 1):match('^%s*(.*%S)')
					type = t:match('^%S*')
				end

				if type then
					desc = t:sub(#type + 1):match('^%s*(.*%S)')
				end
				local errfn = function(message, start, stop)
					local pos = text:find(line, 0, true)

					local _, line_no = text:sub(0, pos):gsub('\n', '')
					line_no = line_no + ln
					local col_no = text:find(type, 0, true) - pos

					parse_warning(Span:new(
						line_no,
						col_no,
						line_no,
						col_no + #type
					), message, file)
				end

				if name then
					if not NEXT_TAGS.params then NEXT_TAGS.params = {} end
					if name:match('^%d+$') then
						NEXT_TAGS.params[tonumber(name)] = {
							type = SIGNATURE(type or 'any', false, errfn),
							desc = desc,
						}
					else
						table.insert(NEXT_TAGS.params, {
							name = name,
							type = SIGNATURE(type or 'any', false, errfn),
							desc = desc,
						})
					end
				end
			end
		elseif i == '@RETURN' then
			local t = line:match('@[rR][eE][tT][uU][rR][nN]%s*(.*%S)')
			if t then
				local type_text = t:match('^[^%s]+')
				if type_text then
					local type_sig = SIGNATURE(type_text, false, function(message, start, stop)
						local pos = text:find(line, 0, true)

						local _, line_no = text:sub(0, pos):gsub('\n', '')
						line_no = line_no + ln
						local col_no = text:find(type_text, 0, true) - pos

						parse_warning(Span:new(
							line_no,
							col_no,
							line_no,
							col_no + #type_text
						), message, file)
					end)

					if type_sig then
						local type_desc = t:sub(#type_text + 1):gsub('#]]', ''):match('^%s*(.*%S)')
						NEXT_TAGS.returns = {
							type = type_sig,
							desc = type_desc,
						}
					end
				end
			end
		elseif i == '@TYPE' then
			---@type string|nil
			local t = line:match('@[tT][yY][pP][eE]%s*(.*)$')
			if t then
				NEXT_TAGS.type = {}
				for type_text in t:gmatch('[^%s,]+') do
					local type_sig = SIGNATURE(type_text, false, function(message, start, stop)
						local pos = text:find(line, 0, true)

						local _, line_no = text:sub(0, pos):gsub('\n', '')
						line_no = line_no + ln
						local col_no = text:find(type_text, 0, true) - pos

						parse_warning(Span:new(
							line_no,
							col_no,
							line_no,
							col_no + #type_text
						), message, file)
					end)

					if type_sig then
						table.insert(NEXT_TAGS.type, type_sig)
					end
				end
			end
		elseif i == '@ERROR' then
			if not NEXT_TAGS.error then NEXT_TAGS.error = {} end
			local t = line:gsub('@[eE][rR][rR][oO][rR]%s*', '')
			local err_tp = t:match('^[^%s]+')
			table.insert(NEXT_TAGS.error, {
				type = err_tp,
				text = t:sub(#err_tp + 1),
			})
		elseif i == '@DEBUG' then
			if not imported_annotation(line) then
				inline_annotation(line)
			end
		else
			append_text(line)
		end
	end

	for line in text:gmatch('[^\n]+') do
		if in_debug then
			debug_annotations(line)
		else
			local i = line:upper():match('@[a-zA-Z_]+')
			handle_annotations(i, line)
		end
	end
end

return function()
	return process_comment_annotations, get_tags, wipe_tags
end
