require "src.compiler.tokens"
require "src.compiler.escape_codes"

---@diagnostic disable-next-line
kwds = {
	['for'] = TOK.kwd_for,
	['while'] = TOK.kwd_while,
	['in'] = TOK.kwd_in,
	['do'] = TOK.kwd_do,
	['if'] = TOK.kwd_if,
	['then'] = TOK.kwd_then,
	['elif'] = TOK.kwd_elif,
	['else'] = TOK.kwd_else,
	['end'] = TOK.kwd_end,
	['continue'] = TOK.kwd_continue,
	['break'] = TOK.kwd_break,
	['delete'] = TOK.kwd_delete,
	['subroutine'] = TOK.kwd_subroutine,
	['gosub'] = TOK.kwd_gosub,
	['return'] = TOK.kwd_return,
	['let'] = TOK.kwd_let,
	['initial'] = TOK.kwd_initial,
	['stop'] = TOK.kwd_stop,
	['match'] = TOK.kwd_match,
	['cache'] = TOK.kwd_cache,
	['using'] = TOK.kwd_using,
	['as'] = TOK.kwd_as,
	--[[minify-delete]]['require'] = TOK.kwd_import_file, --[[/minify-delete]]
	['try'] = TOK.kwd_try,
	['catch'] = TOK.kwd_catch,
}

---@diagnostic disable-next-line
opers = {
	['for'] = TOK.kwd_for_expr,
	['if'] = TOK.kwd_if_expr,
	['else'] = TOK.kwd_else_expr,
	['+'] = TOK.op_plus,
	['-'] = TOK.op_minus,
	['*'] = TOK.op_times,
	['//'] = TOK.op_idiv,
	['/'] = TOK.op_div,
	['%'] = TOK.op_mod,
	['^'] = TOK.op_exponent,
	[':'] = TOK.op_slice,
	['&'] = TOK.op_count,
	['not'] = TOK.op_not,
	['and'] = TOK.op_and,
	['or'] = TOK.op_or,
	['xor'] = TOK.op_xor,
	['in'] = TOK.op_in,
	['exists'] = TOK.op_exists,
	['like'] = TOK.op_like,
	['=>'] = TOK.op_arrow,
	['>='] = TOK.op_ge,
	['>'] = TOK.op_gt,
	['<='] = TOK.op_le,
	['<'] = TOK.op_lt,
	['=='] = TOK.op_eq,
	['='] = TOK.op_eq,
	['~='] = TOK.op_ne,
	['!='] = TOK.op_ne,
	[','] = TOK.op_comma,
	['.'] = TOK.op_dot,
}

local oper_block = {
	['/'] = { '/' },
	['>'] = { '=' },
	['<'] = { '=' },
	['='] = { '=', '>' },
}

---@diagnostic disable-next-line
literals = {
	['true'] = TOK.lit_boolean,
	['false'] = TOK.lit_boolean,
	['null'] = TOK.lit_null,
}

--[[minify-delete]]
EXPORT_LINES = {}
EXPORT_NEXT_TOKEN = false
ELIDE_LINES = {}
ELIDE_NEXT_TOKEN = false

---Some comments can give hints about what commands exist, and suppress "unknown command" errors.
---Process these annotations.
---@param text string The comment text to process, including the leading # character.
local function process_comment_annotations(text)
	local comment_text = text:upper()

	for i in comment_text:gmatch('@[%w_]+') do
		if i == '@COMMANDS' then
			local msg = text:match('@[cC][oO][mM][mM][aA][nN][dD][sS][^%w_]([^\n]*)')
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
		elseif _G['LANGUAGE_SERVER'] and i == '@EXPORT' then
			EXPORT_NEXT_TOKEN = true
		elseif i == '@ALLOW_ELISION' then
			ELIDE_NEXT_TOKEN = true
		end
	end
end
--[[/minify-delete]]

--[[
Takes text and (optional)file name, and returns an iterator for getting the next token.
Throws an error if any token error was found in the input text.

Iterator generates tokens of the form:
{
	text: string,
	id: int,
	line: int,
	col: int,
}
--]]
---@param text string
---@param file string?
---@return function iterator An iterator that fetches the next token when run.
---@return function append_text A function for appending text to the input dynamically.
function Lexer(text, file)
	local line = 1
	local col = 1
	local scopes = {}

	---@param last_paren string
	---@param this_paren string
	local function check_parens(last_paren, this_paren)
		local errtype = {
			['('] = { ['}'] = true, [']'] = true },
			['{'] = { [')'] = true, [']'] = true },
			['['] = { ['}'] = true, [')'] = true },
		}

		local expected = {
			['('] = ')',
			['{'] = '}',
			['['] = ']',
		}

		if errtype[last_paren][this_paren] then
			parse_error(Span:new(line, col, line, col),
				'Mismatched parentheses, expected "' .. expected[last_paren] .. '", got "' .. this_paren .. '"', file)
		end
	end

	local function token_iterator()
		while #text > 0 do
			local match = nil
			local tok_type = TOK.no_value
			local tok_ignore = false
			local curr_scope = scopes[#scopes]
			local real_value = nil
			local curr_scope_c1 = curr_scope and curr_scope:sub(1, 1)

			if curr_scope == nil or curr_scope == '$' then
				--Default parse rules

				--line endings (separate individual commands)
				match = text:match('^[\n;]')
				if match then
					tok_type = TOK.line_ending
				end

				--White space
				if not match then
					match = text:match('^[ \t\r]+')
					if match then tok_ignore = true end
				end

				--Multi-line comments
				if not match then
					match = text:match('^#%[%[')
					if match then
						tok_ignore = true
						match = text:match('^#%[%[.-%]%]')
						if not match then match = text:match('^#%[%[.*') end
						--[[minify-delete]]
						process_comment_annotations(match)
						--[[/minify-delete]]
					end
				end

				--Comments
				if not match then
					match = text:match('^#[^\n]*')
					if match then
						tok_ignore = true
						--[[minify-delete]]
						process_comment_annotations(match)
						--[[/minify-delete]]
					end
				end

				--multiline string start
				if not match then
					match = text:match('^"""')
					if not match then match = text:match("^'''") end
					if match then
						tok_type = TOK.string_open
						table.insert(scopes, match)
					end
				end

				--string start
				if not match then
					match = text:match('^[\'"]')
					if match then
						tok_type = TOK.string_open
						table.insert(scopes, match)
					end
				end

				--expression start
				if not match then
					match = text:match('^{')
					if match then
						tok_type = TOK.expr_open
						table.insert(scopes, match)
					end
				end

				--inline command start
				if not match then
					match = text:match('^%${')
					if match then
						tok_type = TOK.command_open
						table.insert(scopes, '$')
					end
				end

				--inline command end
				if not match and curr_scope == '$' then
					match = text:match('^}')
					if match then
						tok_type = TOK.command_close
						table.remove(scopes)
					end
				end

				--[[minify-delete]]
				if _G['IGNORE_MISSING_BRACE'] then
					--expression end.
					if not match then
						match = text:match('^}')
						if match then
							tok_type = TOK.expr_close
							table.remove(scopes)
						end
					end
				end
				--[[/minify-delete]]

				--keywords
				if not match then
					for key, value in pairs(kwds) do
						if (text:sub(1, #key) == key) and not text:sub(#key, #key + 1):match('^[%w_][%w_]') then
							match = key
							tok_type = value

							if match == 'let' or match == 'initial' then
								table.insert(scopes, 'let')
							end
							break
						end
					end
				end

				--non-quoted text
				if not match then
					match = text:match('^[^ \t\n\r"\'{};$]+')
					if match then tok_type = TOK.text end
				end
			elseif curr_scope == '{' or curr_scope == '(' or curr_scope == '[' then
				--Parse rules when inside expressions

				--Ignore white space inside expressions, including line endings
				if not match then
					match = text:match('^\n')
					if match then
						tok_ignore = true
					end
				end
				if not match then
					match = text:match('^[ \t\r]+')
					if match then tok_ignore = true end
				end

				--Multi-line comments
				if not match then
					match = text:match('^#%[%[')
					if match then
						tok_ignore = true
						match = text:match('^#%[%[.-%]%]')
						if not match then match = text:match('^#%[%[.*') end
						--[[minify-delete]]
						process_comment_annotations(match)
						--[[/minify-delete]]
					end
				end

				--Comments
				if not match then
					match = text:match('^#[^\n]*')
					if match then
						tok_ignore = true
						--[[minify-delete]]
						process_comment_annotations(match)
						--[[/minify-delete]]
					end
				end

				--multiline string start
				if not match then
					match = text:match('^"""')
					if not match then match = text:match("^'''") end
					if match then
						tok_type = TOK.string_open
						table.insert(scopes, match)
					end
				end

				--string start
				if not match then
					match = text:match('^[\'"]')
					if match then
						tok_type = TOK.string_open
						table.insert(scopes, match)
					end
				end

				--expression start
				if not match then
					match = text:match('^{')
					if match then
						tok_type = TOK.expr_open
						table.insert(scopes, match)
					end
				end

				--expression end
				if not match then
					match = text:match('^}')
					if match then
						tok_type = TOK.expr_close
						table.remove(scopes)
						check_parens(curr_scope, match)
					end
				end

				--paren close
				if not match then
					match = text:match('^%)')
					if match then
						tok_type = TOK.paren_close
						table.remove(scopes)
						check_parens(curr_scope, match)
					end
				end

				--paren open
				if not match then
					match = text:match('^%(')
					if match then
						tok_type = TOK.paren_open
						table.insert(scopes, match)
					end
				end

				--bracket close
				if not match then
					match = text:match('^%]')
					if match then
						tok_type = TOK.index_close
						table.remove(scopes)
						check_parens(curr_scope, match)
					end
				end

				--bracket open
				if not match then
					match = text:match('^%[')
					if match then
						tok_type = TOK.index_open
						table.insert(scopes, match)
					end
				end

				--inline command start
				if not match then
					match = text:match('^%${')
					if match then
						tok_type = TOK.command_open
						table.insert(scopes, '$')
					end
				end

				--Numbers (can have formats 0xAAAA, 0bAAAA, AA.AAA, A_AAA_AAA.AAA)
				if not match then
					match = text:match('^0[xb][0-9_a-fA-F]*')          --0x12af / 0b0011
					if not match then match = text:match('^%.[0-9]+') end --.123456
					if not match then match = text:match('^[0-9][0-9_]*%.[0-9]+') end --1_234.657
					if not match then match = text:match('^[0-9][0-9_]*') end --1_234_567

					if match then
						local m = match:gsub('_', '')
						local n
						local tp = ''
						if m:sub(2, 2) == 'x' then
							n = tonumber(m:sub(3, #m), 16)
							tp = 'hexadecimal '
						elseif m:sub(2, 2) == 'b' then
							n = tonumber(m:sub(3, #m), 2)
							tp = 'binary '
						else
							n = tonumber(m)
						end

						if n == nil then
							parse_error(Span:new(line, col - 1, line, col + #match - 1),
								'Invalid ' .. tp .. 'number "' .. match .. '"', file)
						end
						tok_type = TOK.lit_number
						real_value = n
					end
				end

				--Operators
				if not match then
					for key, value in pairs(opers) do
						if (text:sub(1, #key) == key) and not text:sub(#key, #key + 1):match('^[%w_][%w_]') then
							--Look ahead to avoid ambiguity with operators
							if not oper_block[key] or std.arrfind(oper_block[key], text:sub(#key + 1, #key + 1), 1) == 0 then
								match = key
								tok_type = value
								break
							end
						end
					end
				end

				--Macro operators
				if not match then
					match = text:match('^!+[%w_]*')
					if match then
						tok_type = TOK.op_exclamation
					end
				end

				--Named constants
				if not match then
					for key, value in pairs(literals) do
						if (text:sub(1, #key) == key) and not text:sub(#key, #key + 1):match('^[%w_][%w_]') then
							match = key
							tok_type = value
							if match == 'true' then
								real_value = true
							elseif match == 'false' then
								real_value = false
							end
							break
						end
					end
				end

				--Variable references
				if not match then
					match = text:match('^[a-zA-Z_][a-zA-Z_0-9]*')
					if match then tok_type = TOK.variable end
				end

				--Special "list of params" and "list of commands" variables
				if not match then
					--Special param indexer syntax, e.g. @1 means the same as @[1]
					match = text:match('^@%d+')
					if match then
						tok_type = TOK.variable
					else
						match = text:match('^[@%$]')
						if match then tok_type = TOK.variable end
					end
				end

				--Special identifiers (can contain special characters)
				if not match then
					match = text:match('^\\[^ \t\n\r"\'%(%)%[%]{};%$]+')
					if match then tok_type = TOK.variable end
				end
			elseif curr_scope_c1 == '"' or curr_scope_c1 == '\'' then
				--Logic for inside strings
				local this_ix = 1
				local this_str = ''
				while true do
					local this_chr = text:sub(this_ix, this_ix)

					if this_chr == '' then
						parse_error(Span:new(line, col + #this_str, line, col + #this_str),
							'Unexpected EOF inside string', file)
						--[[minify-delete]]
						--Hack to get REPL version to not loop forever
						if _G['REPL'] then
							this_chr = curr_scope
							ERRORED = false
						end
						--[[/minify-delete]]
					end

					--Line breaks are only allowed inside triple-quoted strings
					if this_chr == '\n' and #curr_scope == 1 then
						parse_error(Span:new(line, col + #this_str, line, col + #this_str),
							'Unexpected line ending inside string', file)
						--[[minify-delete]]
						--Hack to get REPL version to not loop forever
						if _G['REPL'] then
							this_chr = curr_scope
						end
						--[[/minify-delete]]
					end

					--Once string ends, add text to token list and exit string.
					--If we found an expression instead, add to the stack (only in double-quoted strings).
					local next_chr = text:sub(this_ix + 1, this_ix + 1)
					local quote_end = text:sub(this_ix, this_ix + #curr_scope - 1)
					if quote_end == curr_scope or ((this_chr == '{' or (this_chr == '$' and next_chr == '{')) and curr_scope_c1 ~= '\'') then
						if #this_str > 0 then
							--Insert current built string
							text = text:sub(this_ix, #text)
							---@type Token
							local out = {
								span = Span:new(line, col - 1, line, col + #this_str - 1),
								text = this_str,
								id = TOK.text,
							}
							col = col + #this_str
							return out
						end

						match = this_chr
						if this_chr == '{' then
							--enter expression (add to scope stack)
							tok_type = TOK.expr_open
							table.insert(scopes, match)
						elseif this_chr == '$' then
							--enter inline command eval
							match = '${'
							tok_type = TOK.command_open
							table.insert(scopes, this_chr)
						else
							--exit string (pop to previous scope)
							match = quote_end
							tok_type = TOK.string_close
							table.remove(scopes)
						end

						break
					end

					--Parse escape sequences. Only a few have special meaning, see escape_codes.lua
					if this_chr == '\\' then
						this_ix = this_ix + 1
						this_chr = text:sub(this_ix, this_ix)
						if this_chr == '' then
							parse_error(Span:new(line, col + #this_str, line, col + #this_str),
								'Unexpected EOF inside string (after "\\")', file)
						else
							local found_esc = false
							for search, replace in pairs(ESCAPE_CODES) do
								if text:sub(this_ix, this_ix + #search - 1) == search then
									if type(replace) == 'table' then
										--Special case for hex characters
										local m = text:sub(this_ix - 1, this_ix + 9):match('^\\' ..
											search .. replace.next)
										if m then
											this_chr = replace.op(m:sub(2 + #search, 3 + #search))
											this_ix = this_ix + #m - 2
											found_esc = true
										end
									else
										found_esc = true
										this_ix = this_ix + #search - 1
										this_chr = replace
									end
									break
								end
							end

							if not found_esc then
								parse_error(Span:new(line, col + #this_str, line, col + #this_str),
									'Invalid escape sequence (after "\\")', file)
							end
						end
					end

					this_str = this_str .. this_chr
					this_ix = this_ix + 1
				end
			elseif curr_scope == 'let' then
				--line endings (end of variable declaration)
				match = text:match('^[\n;]')
				if match then
					tok_type = TOK.line_ending
					table.remove(scopes)
				end

				--variable assignment operator (end of variable declaration)
				if not match then
					match = text:match('^=')
					if match then
						tok_type = TOK.op_assign
						table.remove(scopes)
					end
				end

				--expression start indicates that we're setting a sub-value of the variable
				if not match then
					match = text:match('^{')
					if match then
						tok_type = TOK.expr_open
						table.insert(scopes, match)
					end
				end

				--White space
				if not match then
					match = text:match('^[ \t\r]+')
					if match then tok_ignore = true end
				end

				--Variable references
				if not match then
					match = text:match('^[a-zA-Z_][a-zA-Z_0-9]*')
					if match then tok_type = TOK.var_assign end
				end
			end

			--Append currently matched token to token list
			if match then
				local num_line_endings = #match:gsub('[^\n]', '')
				line = line + num_line_endings
				if num_line_endings > 0 then col = 1 end
				local lines = std.split(match, '\n')
				col = col + #(lines[#lines])

				text = text:sub(#match + 1, #text)
				if not tok_ignore then
					--[[minify-delete]]
					if EXPORT_NEXT_TOKEN and tok_type ~= TOK.line_ending then
						EXPORT_LINES[line] = true
						EXPORT_NEXT_TOKEN = false
					end

					if ELIDE_NEXT_TOKEN and tok_type ~= TOK.line_ending then
						ELIDE_LINES[line] = true
						ELIDE_NEXT_TOKEN = false
					end
					--[[/minify-delete]]

					---@type Token
					return {
						span = Span:new(line, col - #match - 1, line, col - 1),
						text = match,
						id = tok_type,
						value = real_value,
						filename = file,
					}
				end
			else
				parse_error(Span:new(line, col, line, col), 'Unexpected character "' .. text:sub(1, 1) .. '"', file)
				col = col + 1
				text = text:sub(2, #text)
				break
			end
		end

		--Make sure all strings, parens, and brackets all match up.
		local remaining_scope = scopes[#scopes]
		local rem_scope_c1 = remaining_scope and remaining_scope:sub(1, 1)
		if rem_scope_c1 == '"' or rem_scope_c1 == '\'' then
			parse_error(Span:new(line, col, line, col), 'Unexpected EOF inside string', file)
		elseif remaining_scope == '(' then
			--[[minify-delete]]
			if not _G['IGNORE_MISSING_BRACE'] then --[[/minify-delete]]
				parse_error(Span:new(line, col, line, col), 'Missing parenthesis, expected ")"', file)
				--[[minify-delete]]
			end --[[/minify-delete]]
		elseif remaining_scope == '[' then
			--[[minify-delete]]
			if not _G['IGNORE_MISSING_BRACE'] then --[[/minify-delete]]
				parse_error(Span:new(line, col, line, col), 'Missing bracket, expected "]"', file)
				--[[minify-delete]]
			end --[[/minify-delete]]
		elseif remaining_scope == '{' then
			--[[minify-delete]]
			if not _G['IGNORE_MISSING_BRACE'] then --[[/minify-delete]]
				parse_error(Span:new(line, col, line, col), 'Missing brace after expression, expected "}"', file)
				--[[minify-delete]]
			end --[[/minify-delete]]
		elseif remaining_scope == '$' then
			parse_error(Span:new(line, col, line, col), 'Missing brace after command eval, expected "}"', file)
		end
	end

	--[[minify-delete]]
	local function append_text(new_text)
		text = text .. new_text
	end
	--[[/minify-delete]]

	return token_iterator --[[minify-delete]], append_text --[[/minify-delete]]
end
