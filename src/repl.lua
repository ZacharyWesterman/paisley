require "src.shared.stdlib"
require "src.shared.json"
require "src.shared.closest_word"

require "src.compiler.lex"
require "src.compiler.syntax"
require "src.compiler.fold_constants"
require "src.compiler.semantics"
require "src.compiler.codegen"

ALLOWED_COMMANDS = V3
require "src.shared.builtin_commands"

--[[SETUP FOR RUNTIME]]
-- local old_error = error
function error(text)
	if text then print(text) end
	-- old_error()
	ERRORED = true
end

local socket_installed, socket = pcall(require, 'socket')
ENDED = false

local line_no = 0
function output(value, port)
	if port == 1 then
		--continue program
	elseif port == 2 then
		--run a non-builtin command (currently not supported outside of Plasma)
		error('Error on line '.. line_no .. ': Cannot run program `' .. std.str(value) .. '`')
	elseif port == 3 then
		ENDED = true --program successfully completed
	elseif port == 4 then
		--delay execution for an amount of time
		os.execute('sleep ' .. value)
		V5 = nil
	elseif port == 5 then
		--get current time (seconds since midnight)
		local date = os.date('*t', os.time())
		local sec_since_midnight = date.hour*3600 + date.min*60 + date.sec

		if socket_installed then
			sec_since_midnight = sec_since_midnight + (math.floor(socket.gettime() * 1000) % 1000 / 1000)
		end

		V5 = sec_since_midnight --command return value
	elseif port == 6 then
		if value == 2 then
			--get system date (day, month, year)
			local date = os.date('*t', os.time())
			V5 = {date.day, date.month, date.year} --command return value
		elseif value == 1 then
			--get system time (seconds since midnight)
			local date = os.date('*t', os.time())
			local sec_since_midnight = date.hour*3600 + date.min*60 + date.sec

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
	else
		print(port, json.stringify(value))
	end
end

function output_array(value, port) output(value, port) end

local tmp = ALLOWED_COMMANDS
V1 = '[]'
V4 = os.time()
V5 = nil
require "src.runtime"
ALLOWED_COMMANDS = tmp
--[[/SETUP FOR RUNTIME]]

INTERRUPT = true
USER_SIGINT = false
local signal = require("posix.signal")
signal.signal(signal.SIGINT, function(signum)
	io.write('\r')
	if INTERRUPT then os.exit(128 + signum) end
	USER_SIGINT = true
end)

IGNORE_MISSING_BRACE = true
SHOW_MULTIPLE_ERRORS = true

local indent = 0
local indent_tokens = {
	[TOK.kwd_for] = true,
	[TOK.kwd_while] = true,
	[TOK.kwd_then] = true,
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
local token_cache = {}
local lexer, append_text = Lexer('')

for input_line in function() return io.read('*l') end do
	ERRORED = false

	append_text(input_line)
	for token in lexer do
		if indent_tokens[token.id] then
			indent = indent + 1
		elseif dedent_tokens[token.id] then
			indent = math.max(0, indent - 1)
		end
		table.insert(token_cache, token)
	end

	if indent > 0 then io.write('... ') else
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
			root = SemanticAnalyzer(parser.get())
		end

		--Generate bytecode
		bytecode = nil
		if root then
			bytecode = generate_bytecode(root)
		end

		--Run the bytecode
		--Need some way to cancel?
		if not ERRORED then
			ENDED = false
			local tmp = ALLOWED_COMMANDS
			V1 = json.stringify(bytecode)
			V4 = os.time()
			V5 = nil
			INIT()
			ALLOWED_COMMANDS = tmp

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
	end
end
print()
