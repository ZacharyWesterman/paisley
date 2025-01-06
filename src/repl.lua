function error(text)
	if text then print(text) end
	ERRORED = true
end

KEEP_DEAD_CODE = true
ALLOW_SUBROUTINE_ELISION = true --Allow any redeclaration of a subroutine to elide any existing definition, rather than error.

require "src.shared.stdlib"
require "src.shared.json"
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
	['?'] = '', --stdout of command
	['!'] = nil, --result of execution
}

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
		--Print text or error
		table.remove(value, 1)
		print(std.str(value))
		io.flush()
		V5 = nil
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
			['?'] = '', --stdout of command
			['!'] = nil, --result of execution
		}

		local program = io.popen(value[2] .. ' 2>&1', 'r')
		if program then
			local line = program:read('*l')
			while line do
				if value[1] ~= '?' then print(line) end
				if #CMD_LAST_RESULT['?'] > 0 then line = '\n' .. line end
				CMD_LAST_RESULT['?'] = CMD_LAST_RESULT['?'] .. line

				line = program:read('*l')
			end

			---@diagnostic disable-next-line
			CMD_LAST_RESULT['!'] = program:close()
		end

		V5 = CMD_LAST_RESULT[value[1]]
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
}
local dedent_tokens = {
	[TOK.expr_close] = true,
	[TOK.kwd_end] = true,
}

io.write('>>> ')
io.flush()
local token_cache = {}
local subroutine_cache = {} --Keep cache of all subroutines the user creates
local lexer, append_text = Lexer('')

for input_line in function() return io.read('*l') end do
	ERRORED = false
	SHOW_MULTIPLE_ERRORS = true

	if append_text then append_text(input_line .. '\n') end

	for token in lexer do
		if indent_tokens[token.id] then
			indent = indent + 1
		elseif dedent_tokens[token.id] then
			indent = math.max(0, indent - 1)
		end
		table.insert(token_cache, token)
	end

	if indent > 0 then
		---@type Token
		local nl = {
			span = Span:new(0, 0, 0, 0),
			id = TOK.line_ending,
			text = '\n',
		}
		table.insert(token_cache, nl)
		io.write('... ')
		io.flush()
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
		while parser.fold() do if ERRORED then break end end

		--Run semantic analysis
		local root = nil
		if not ERRORED and #parser.get() > 0 then
			root = parser.get()

			--Reappend subroutine cache into program.
			for _, subroutine_ast in pairs(subroutine_cache) do
				root[1] = {
					id = TOK.program,
					span = root[1].span,
					text = 'stmt_list',
					children = { subroutine_ast, root[1], },
				}
			end

			root = SemanticAnalyzer(parser.get())
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
		token_cache = {}
		io.write('>>> ')
		io.flush()
	end
end
print()
