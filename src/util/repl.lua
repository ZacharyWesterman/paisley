REPL = true

function error(text)
	if text then print(text) end
	ERRORED = true
end

KEEP_DEAD_CODE = true
ALLOW_SUBROUTINE_ELISION = true --Allow any redeclaration of a subroutine to elide any existing definition, rather than error.

require "src.shared.stdlib"
require "src.shared.json"
require "src.shared.xml"
require "src.shared.closest_word"

require "src.compiler.type_signature"
require "src.compiler.lex"
require "src.compiler.syntax"
require "src.compiler.fold_constants"
require "src.compiler.semantics"
require "src.compiler.codegen"

ALLOWED_COMMANDS = V3
require "src.shared.builtin_commands"

--[[SETUP FOR RUNTIME]]
local socket_installed, socket = pcall(require, 'socket')
ENDED = false

local line_no = 0
local CMD_LAST_RESULT = {
	['='] = nil, --result of execution
	['?'] = '', --stdout of command
	['!'] = '', --stderr of command
	['?!'] = '', --stdout and stderr of command
}

local TMP1 = '.paisley.program.tmp.stdout'
local TMP2 = '.paisley.program.tmp.stderr'

local function clear()
	os.execute('clear')
end
local function printf(text, color)
	io.write(text)
	io.flush()
end

function output(value, port)
	if port == 1 then
		--continue program
	elseif port == 2 then
		--run a non-builtin command (currently not supported outside of Plasma)
		error('Error on line ' .. line_no .. ': Cannot run program `' .. std.str(value) .. '`')
	elseif port == 3 then
		ENDED = true --program successfully completed
	elseif port == 4 then
		--delay execution for an amount of time
		os.execute('sleep ' .. value)
		V5 = nil
	elseif port == 5 then
		--get current time (seconds since midnight)
		local date = os.date('*t', os.time())
		local sec_since_midnight = date.hour * 3600 + date.min * 60 + date.sec

		if socket_installed then
			sec_since_midnight = sec_since_midnight + (math.floor(socket.gettime() * 1000) % 1000 / 1000)
		end

		V5 = sec_since_midnight --command return value
	elseif port == 6 then
		if value == 2 then
			--get system date (day, month, year)
			local date = os.date('*t', os.time())
			V5 = { date.day, date.month, date.year } --command return value
		elseif value == 1 then
			--get system time (seconds since midnight)
			local date = os.date('*t', os.time())
			local sec_since_midnight = date.hour * 3600 + date.min * 60 + date.sec

			if socket_installed then
				sec_since_midnight = sec_since_midnight + (math.floor(socket.gettime() * 1000) % 1000 / 1000)
			end

			V5 = sec_since_midnight --command return value
		end
	elseif port == 7 then
		V5 = nil
		--Print text or error
		local cmd = value[1]
		table.remove(value, 1)
		local args = std.str(value)
		if cmd == 'stdout' then
			io.write(args)
		elseif cmd == 'stderr' then
			io.write(io.stderr, args)
		elseif cmd == 'stdin' then
			V5 = io.read('*l')
		elseif cmd == 'clear' then
			clear()
		else
			print(args)
		end
		io.flush()
	elseif port == 8 then
		--value is current line number
	elseif port == 9 then
		--Get the output of the last run unix command
		if value[2] == '' then
			V5 = CMD_LAST_RESULT[value[1]]
			return
		end

		--Run new unix command
		CMD_LAST_RESULT = {
			['='] = nil, --result of execution
			['?'] = '', --stdout of command
			['!'] = '', --stderr of command
			['?!'] = '', --stdout and stderr of command
		}

		local cmd = value[2]

		--By default (both captured), both stdout and stderr will just go to temp files and not be streamed.
		local pipe = cmd .. '2>' .. TMP2 .. ' 1>' .. TMP1
		--If capturing stderr, then stderr will be in file, stdout will be streamed.
		if value[1] == '!' then pipe = cmd .. '2>' .. TMP2 .. ' | tee ' .. TMP1 end
		--If capturing stdout, then stdout will be in file, stderr will be streamed.
		if value[1] == '?' then pipe = cmd .. '1>' .. TMP1 .. ' 2>&1 | tee ' .. TMP2 end
		--If capturing neither, then both will be streamed.
		if value[1] == '=' then pipe = '{ { ' .. cmd .. '; } | tee ' .. TMP1 .. '; } 2>&1 | tee ' .. TMP2 end

		cmd = pipe

		--Stash working dir
		local old_dir = ''
		if _G['LFS_INSTALLED'] then
			old_dir = _G['LFS'].currentdir()
			_G['LFS'].chdir(WORKING_DIR)
		end

		local program = io.popen(cmd, 'r')
		if program then
			local chr = program:read(1)
			while chr do
				printf(chr)
				chr = program:read(1)
			end

			--Read stream results from files
			local stdout = io.open(TMP1, 'r')
			local stderr = io.open(TMP2, 'r')
			if stdout then
				CMD_LAST_RESULT['?'] = stdout:read('*all')
				stdout:close()
				os.remove(TMP1)
			end
			if stderr then
				CMD_LAST_RESULT['!'] = stderr:read('*all')
				stderr:close()
				os.remove(TMP2)
			end
			CMD_LAST_RESULT['?!'] = CMD_LAST_RESULT['?'] .. CMD_LAST_RESULT['!']

			--Trim trailing newline from command capture
			for _, i in pairs({ '?', '!', '?!' }) do
				if CMD_LAST_RESULT[i]:sub(#CMD_LAST_RESULT[i]) == '\n' then
					CMD_LAST_RESULT[i] = CMD_LAST_RESULT[i]:sub(1, #CMD_LAST_RESULT[i] - 1)
				end
			end

			--Store exec result
			CMD_LAST_RESULT['='] = program:close()
		end

		V5 = CMD_LAST_RESULT[value[1]]

		--Restore working dir
		if _G['LFS_INSTALLED'] then
			if CMD_LAST_RESULT['='] == true and value[2]:sub(1, 5) == '"cd" ' then
				WORKING_DIR = WORKING_DIR .. '/' .. value[2]:sub(7):match('^[^"]+')
			end
			_G['LFS'].chdir(old_dir)
		end
	else
		print(port, json.stringify(value))
	end
end

function output_array(value, port) output(value, port) end

local tmp = ALLOWED_COMMANDS
V1 = '[[]]'
V4 = os.time()
V5 = nil
require "src.runtime"
ALLOWED_COMMANDS = tmp
--[[/SETUP FOR RUNTIME]]

INTERRUPT = true
USER_SIGINT = false
local signal_installed, signal = pcall(require, 'posix.signal')
if signal_installed then
	signal.signal(signal.SIGINT, function(signum)
		io.write('\n')
		if INTERRUPT then os.exit(128 + signum) end
		USER_SIGINT = true
	end)
end

IGNORE_MISSING_BRACE = true
SHOW_MULTIPLE_ERRORS = true

local indent = 0
local indent_tokens = {
	[TOK.kwd_for] = true,
	[TOK.kwd_while] = true,
	[TOK.kwd_if] = true,
	[TOK.kwd_else] = true,
	[TOK.kwd_elif] = true,
	[TOK.kwd_subroutine] = true,
	[TOK.expr_open] = true,
	[TOK.kwd_try] = true,
}
local dedent_tokens = {
	[TOK.expr_close] = true,
	[TOK.kwd_end] = true,
}

local token_cache = {}
local subroutine_cache = {} --Keep cache of all subroutines the user creates
local lexer, append_text = Lexer('')

local curses_installed, curses = pcall(require, 'curses')

--Default readline, used when curses is not installed
local function readline()
	return io.read('*l')
end
print = function(text)
	if text ~= nil then
		printf(text .. '\n')
	else
		printf('\n')
	end
end
local function prompt(multiline)
	if multiline then
		printf('... ')
	else
		printf('>>> ')
	end
end


--If curses is installed, use that for REPL
--It gives better terminal control
if curses_installed then
	local stdscr = curses.initscr()
	curses.echo(false)
	stdscr:scrollok(true)

	local colors = {
		maroon = 1,
		green = 2,
		olive = 3,
		navy = 4,
		purple = 5,
		teal = 6,
		silver = 7,
		gray = 8,
		red = 9,
		lime = 10,
		yellow = 11,
		blue = 12,
		magenta = 13,
		aqua = 14,
		white = 15,
		cyan = 51,
		orange = 172,
	}

	local entity = {
		keyword = colors.purple,
		comment = colors.gray,
		string = colors.green,
		escape = colors.cyan,
		braces = colors.white,
		literal = colors.cyan,
		operator = colors.orange,
		command = colors.blue,
		funccall = colors.yellow,
		error = colors.red,
		macro = colors.lime,
	}

	if curses.has_colors() then
		--Init colors
		curses.start_color()
		curses.use_default_colors()
		for i = 0, curses.color_pairs() - 1 do
			curses.init_pair(i, i, -1)
		end

		-- for i = 0, 50 do
		-- 	stdscr:attron(curses.color_pair(i))
		-- 	stdscr:addstr(i .. ' ')
		-- 	stdscr:attroff(curses.color_pair(i))
		-- end

		prompt = function(multiline)
			local text = '>>> '
			if multiline then text = '... ' end
			printf(text, colors.gray)
		end
	end

	local perm_scopes = {}

	local pe = parse_error
	---@diagnostic disable-next-line
	parse_error = function(span, msg, file)
		perm_scopes = {}
		pe(span, msg, file)
	end

	local function printfmt(text)
		local cmd_found = false
		local scopes = {}
		for i = 1, #perm_scopes do
			table.insert(scopes, perm_scopes[i])
		end

		while #text > 0 do
			local match = nil
			local scope = scopes[#scopes]

			if not scope or scope == '$' then
				--Comments
				if not match then
					match = text:match('^#.*')
					if match then printf(match, entity.comment) end
				end

				--Piping operators
				if not _G['RESTRICT_TO_PLASMA_BUILD'] and not match then
					match = text:match('^[^\'"%$%{%} \t#;|<>]*[|<>][^\'"%$%{%} \t#;|<>]*')
					if match then
						printf(match, entity.operator)
						cmd_found = false
					end
				end

				--Keywords, and first command param
				if not match then
					if not _G['RESTRICT_TO_PLASMA_BUILD'] then
						match = text:match('^[^\'"%$%{%} \t#;|<>]+')
					else
						match = text:match('^[^\'"%$%{%} \t#;]+')
					end

					if match then
						if (scope and match == 'gosub') or (not scope and (kwds[match] or match == 'define')) then
							cmd_found = true
							if match == 'end' or match == 'then' or match == 'do' or match == 'try' then
								cmd_found = false
							end

							printf(match, entity.keyword)
						elseif not cmd_found then
							cmd_found = true
							printf(match, entity.command)
						else
							printf(match)
						end
					end
				end

				--Strings
				if not match then
					match = text:match('^["\']')
					if match then
						table.insert(scopes, match)
						printf(match, entity.string)
					end
				end

				--End inline command eval
				if scope == '$' and not match and text:sub(1, 1) == '}' then
					match = text:sub(1, 1)
					printf(match, entity.braces)
					if #scopes > 0 then table.remove(scopes) end
				end

				--Expression / command eval scope enter
				if not match then
					match = text:match('^%$?%{')
					if match then
						if match == '${' then cmd_found = false end
						printf(match, entity.braces)
						table.insert(scopes, match:sub(1, 1))
					end
				end
			elseif scope == '"' or scope == "'" then
				--Expression / command eval scope enter
				match = text:match('^%$?%{')
				if match then
					if match == '${' then cmd_found = false end
					printf(match, entity.braces)
					table.insert(scopes, match:sub(1, 1))
				else
					match = text:sub(1, 1)
					if match == '\\' then
						local color = entity.error

						--Escape sequences
						for k, v in pairs(ESCAPE_CODES) do
							if text:sub(2, 1 + #k) == k then
								if type(v) == 'table' and v.next then
									local next = text:match('^\\' .. k .. v.next)
									if next then
										match = next
										color = entity.escape
									else
										match = '\\' .. k
									end
								else
									match = text:sub(1, 1 + #k)
									color = entity.escape
								end
								break
							end
						end

						printf(match, color)
					else
						printf(match, entity.string)
					end

					if match == scope then
						if #scopes > 0 then table.remove(scopes) end
					end
				end
			elseif scope == '{' then
				--Comments
				if not match then
					match = text:match('^#.*')
					if match then printf(match, entity.comment) end
				end

				--Function calls
				if not match then
					match = text:match('^[%w_]+%s*%(')
					if match then
						match = match:match('^[%w_]+')
						if BUILTIN_FUNCS[match] then
							printf(match, entity.funccall)
						else
							printf(match, entity.error)
						end
					end
				end

				--Special gosub 'function syntax' calls
				if not match then
					match = text:match('^%\\[^\'"%$%{%}%(%) \t#;]*')
					if match then
						printf(match, entity.funccall)
					end
				end

				--Number literals
				if not match then
					match = text:match('^0x[%da-fA-F_]*')
					local invalid = false
					if match and not text:match('^0x[%da-fA-F_]+') then invalid = true end
					if not match then
						match = text:match('^0b[01_]*')
						if match and not text:match('^0b[01_]+') then invalid = true end
					end
					if not match then
						match = text:match('^0c[0-7_]*')
						if match and not text:match('^0c[0-7_]+') then invalid = true end
					end
					if not match then match = text:match('^%d+%.%d+') end
					if not match then match = text:match('^%d+') end
					if match then
						if invalid then
							printf(match, entity.error)
						else
							printf(match, entity.literal)
						end
					end
				end

				--Literals and keyword operators
				if not match then
					match = text:match('^[%w_]+')
					if match then
						if literals[match] then
							printf(match, entity.literal)
						elseif opers[match] then
							printf(match, entity.operator)
						else
							printf(match)
						end
					end
				end

				--Macros
				if not match then
					match = text:match('^!+[%w_]*')
					if match then
						printf(match, entity.macro)
					end
				end

				--Non-keyword operators
				if not match then
					match = text:sub(1, 2)
					if opers[match] then
						printf(match, entity.operator)
					else
						match = text:sub(1, 1)
						if opers[match] then
							printf(match, entity.operator)
						else
							match = nil
						end
					end
				end

				--Strings
				if not match then
					match = text:match('^["\']')
					if match then
						table.insert(scopes, match)
						printf(match, entity.string)
					end
				end

				--Expression scope exit
				if not match and text:sub(1, 1) == '}' then
					match = text:sub(1, 1)
					printf(match, entity.braces)
					if #scopes > 0 then table.remove(scopes) end
				end
				--Expression / command eval scope enter
				if not match then
					match = text:match('^%$?%{')
					if match then
						if match == '${' then cmd_found = false end
						printf(match, entity.braces)
						table.insert(scopes, match:sub(1, 1))
					end
				end
			end

			if not match then
				match = text:sub(1, 1)

				if match ~= ' ' and match ~= '\t' then cmd_found = true end

				if scope ~= '"' and scope ~= "'" and match == ';' then
					cmd_found = false
					printf(match, entity.comment)
				else
					printf(match)
				end
			end

			text = text:sub(#match + 1, #text)
		end

		return scopes
	end

	readline = function()
		local text = ''
		local y0, x0 = stdscr:getyx()
		local scopes = {}

		while true do
			local c = stdscr:getch()
			local _, x = stdscr:getyx()

			if c == 4 then
				--Ctrl-D (EOF)
				return nil
			elseif c == 127 then
				--Backspace
				local before = text:sub(1, x - x0 - 1)
				local after = text:sub(x - x0 + 1, #text)
				text = before .. after

				--Reprint line so syntax highlighting is updated
				stdscr:move(y0, x0)
				scopes = printfmt(text .. ' ')

				x = math.max(x0, x - 1)
				stdscr:move(y0, x)
			elseif c == 27 then
				--Special keys
				local k1, k2 = stdscr:getch(), stdscr:getch()
				if k1 == 91 and k2 == 68 then
					--left arrow
					x = math.max(x0, x - 1)
					stdscr:move(y0, x)
				elseif k1 == 91 and k2 == 67 then
					--right arrow
					x = math.min(x0 + #text, x + 1)
					stdscr:move(y0, x)
				elseif k1 == 91 and k2 == 51 then
					--delete
					local before = text:sub(1, x - x0)
					local after = text:sub(x - x0 + 2, #text)
					text = before .. after

					--Reprint line so syntax highlighting is updated
					stdscr:move(y0, x0)
					scopes = printfmt(text .. ' ')

					x = math.max(x0, x)
					stdscr:move(y0, x)

					stdscr:getch() --Extract the extra '~' that comes in.
				else
					--Some unknown control sequence
					-- printf('CTRL[' .. k1 .. ',' .. k2 .. ']')
				end
			elseif c < 256 then
				--Regular characters
				c = string.char(c)
				if c == '\n' then
					perm_scopes = scopes
					break
				end
				if c == '\t' then
					c = ' '
				end

				text = text:sub(1, x - x0) .. c .. text:sub(x - x0 + 1, #text)

				--Reprint line so syntax highlighting is updated
				stdscr:move(y0, x0)
				scopes = printfmt(text)
				stdscr:move(y0, x + #c)
			else
				--Just ignore window events
				-- return nil
			end
		end

		stdscr:addstr('\n')
		stdscr:move(y0 + 1, 0)
		return text
	end

	printf = function(text, color)
		if color then stdscr:attron(curses.color_pair(color)) end
		stdscr:addstr(text)
		if color then stdscr:attroff(curses.color_pair(color)) end
	end

	---Override the print function to handle terminal colors
	---@param text string|nil
	print = function(text)
		if text ~= nil then
			if curses_installed then
				local sections = {}
				local current_color = nil

				-- Split terminal color groups into sections
				local pattern = '\27%[[0-9;]+m'
				local c = {
					['\27[0;31m'] = colors.red,
					['\27[0;33m'] = colors.yellow,
				}
				local i = text:find(pattern)
				while i do
					local m = text:match(pattern)

					table.insert(sections, { text:sub(1, i - 1), current_color })
					current_color = c[m]

					text = text:sub(i + #m, #text)
					i = text:find(pattern)
				end
				table.insert(sections, { text, current_color })

				for _, section in ipairs(sections) do
					printf(section[1], section[2])
				end
				printf('\n')
			else
				printf(text .. '\n')
			end
		else
			printf('\n')
		end
	end

	clear = function()
		stdscr:clear()
	end
end

---@diagnostic disable-next-line
printf('Paisley ' .. VERSION .. ' interactive REPL.\n')
printf('Type `stop` or press Ctrl-D to quit.\n')
prompt(false)

local in_expr = 0
for input_line in readline do
	ERRORED = false
	SHOW_MULTIPLE_ERRORS = true

	if append_text then append_text(input_line .. '\n') end

	for token in lexer do
		if indent_tokens[token.id] then
			if in_expr == 0 then indent = indent + 1 end
		elseif dedent_tokens[token.id] then
			indent = math.max(0, indent - 1)
		end
		table.insert(token_cache, token)

		if token.id == TOK.expr_open then in_expr = in_expr + 1 end
		if token.id == TOK.expr_close then in_expr = in_expr - 1 end
	end

	if indent > 0 then
		prompt(true)
	elseif not ERRORED then
		--Make sure braces match up (since we disabled their context in the lexer)
		local braces = {}
		for i = 1, #token_cache do
			if token_cache[i].id == TOK.expr_open then
				table.insert(braces, token_cache[i])
			elseif token_cache[i].id == TOK.expr_close then
				if #braces == 0 then
					parse_error(token_cache[i].span, 'Unexpected character "}"')
				else
					table.remove(braces)
				end
			elseif token_cache[i].id == TOK.kwd_stop then
				os.exit(0)
			end
		end

		if #braces > 0 then
			parse_error(braces[#braces].span, 'Missing brace after expression, expected "}"')
			token_cache = {}
		end

		--Parse the tokens into an AST
		local parser = SyntaxParser(token_cache)
		local ast = parser()
		local root

		--Run semantic analysis
		if not ERRORED then
			--Reappend subroutine cache into program.
			for _, subroutine_ast in pairs(subroutine_cache) do
				root = {
					id = TOK.program,
					span = root[1].span,
					text = 'stmt_list',
					children = { subroutine_ast, root, },
				}
			end

			root = SemanticAnalyzer(ast)
		end

		--If we didn't hit any compile errors, then add any subroutines to the cache.
		if not ERRORED and root then
			--Fun simplification available here:
			--Since Paisley requires all subroutines to be defined at the top level
			--(and program nodes get flattened), we don't have to do a full recursive search.
			--Just check if the root node IS or CONTAINS subroutines.
			if root.id == TOK.subroutine then
				subroutine_cache[root.text] = root
			elseif root.id == TOK.program then
				for i = 1, #root.children do
					if root.children[i].id == TOK.subroutine then
						subroutine_cache[root.children[i].text] = root.children[i]
					end
				end
			end
		end

		--Generate bytecode
		local bytecode = nil
		if not ERRORED and root then
			bytecode = generate_bytecode(root)
		end

		--Run the bytecode
		--Need some way to cancel?
		if not ERRORED and bytecode then
			ENDED = false
			local tmp = ALLOWED_COMMANDS
			V1 = json.stringify(bytecode)
			V4 = os.time()
			V5 = nil
			local tmp2 = VARS
			INIT()
			ALLOWED_COMMANDS = tmp
			if tmp2 then VARS = tmp2 end

			INTERRUPT = false
			while not ENDED and not USER_SIGINT do
				RUN()
			end
			USER_SIGINT = false
			INTERRUPT = true
		end

		--Done running, wait ont next line
		if not ERRORED then
			token_cache = {}
			prompt(false)
		end
	end

	if ERRORED then
		token_cache = {}
		prompt(false)
	end
end
print()
