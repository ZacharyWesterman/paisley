require "src.compiler.tokens"

local kwds = {
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
}

local opers = {
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
	['/'] = '/',
	['>'] = '=',
	['<'] = '=',
	['='] = '=',
}

local literals = {
	['true'] = TOK.lit_boolean,
	['false'] = TOK.lit_boolean,
	['null'] = TOK.lit_null,
}

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
function Lexer(text, file)
	local line = 1
	local col = 1
	local scopes = {}

	---@param last_paren string
	---@param this_paren string
	local function check_parens(last_paren, this_paren)
		local errtype = {
			['('] = {['}']=true, [']']=true},
			['{'] = {[')']=true, [']']=true},
			['['] = {['}']=true, [')']=true},
		}

		local expected = {
			['('] = ')',
			['{'] = '}',
			['['] = ']',
		}

		if errtype[last_paren][this_paren] then
			parse_error(Span:new(line, col, line, col), 'Mismatched parentheses, expected "'..expected[last_paren]..'", got "'..this_paren..'"', file)
		end
	end

	local function token_iterator()
		while #text > 0 do
			local match = nil
			local tok_type = TOK.no_value
			local tok_ignore = false
			local curr_scope = scopes[#scopes]
			local real_value = nil

			if curr_scope == nil or curr_scope == '$' then
				--Default parse rules

				--line endings (separate individual commands)
				match = text:match('^[\n;]')
				if match then
					tok_type = TOK.line_ending

					if match ~= ';' then
						line = line + 1
						col = 0
					end
				end

				--White space
				if not match then
					match = text:match('^[ \t\r]+')
					if match then tok_ignore = true end
				end

				--Comments
				if not match then
					match = text:match('^#[^\n]*')
					if match then tok_ignore = true end
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

				--keywords
				if not match then
					for key, value in pairs(kwds) do
						if (text:sub(1, #key) == key) and not text:sub(#key,#key+1):match('^%w%w') then
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
						line = line + 1
						col = 0
						tok_ignore = true
					end
				end
				if not match then
					match = text:match('^[ \t\r]+')
					if match then tok_ignore = true end
				end

				--Comments
				if not match then
					match = text:match('^#[^\n]*')
					if match then tok_ignore = true end
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
					match = text:match('^0[xb][0-9_a-fA-F]*') --0x12af / 0b0011
					if not match then match = text:match('^%.[0-9]+') end --.123456
					if not match then match = text:match('^[0-9][0-9_]*%.[0-9]+') end --1_234.657
					if not match then match = text:match('^[0-9][0-9_]*') end --1_234_567

					if match then
						local m = match:gsub('_', '')
						local n
						local tp = ''
						if m:sub(2,2) == 'x' then
							n = tonumber(m:sub(3, #m), 16)
							tp = 'hexadecimal '
						elseif m:sub(2,2) == 'b' then
							n = tonumber(m:sub(3, #m), 2)
							tp = 'binary '
						else
							n = tonumber(m)
						end

						if n == nil then
							parse_error(Span:new(line, col, line, col), 'Invalid '..tp..'number "'..match..'"', file)
						end
						tok_type = TOK.lit_number
						real_value = n
					end
				end

				--Operators
				if not match then
					for key, value in pairs(opers) do
						if (text:sub(1, #key) == key) and not text:sub(#key,#key+1):match('^%w%w') then
							--Look ahead to avoid ambiguity with operators
							if not oper_block[key] or text:sub(#key + 1, #key + 1) ~= oper_block[key] then
								match = key
								tok_type = value
								break
							end
						end
					end
				end

				--Lambda operators
				if not match then
					match = text:match('^!+%w*')
					if match then
						tok_type = TOK.op_exclamation
					end
				end

				--Named constants
				if not match then
					for key, value in pairs(literals) do
						if (text:sub(1, #key) == key) and not text:sub(#key,#key+1):match('^%w%w') then
							match = key
							tok_type = value
							if match == 'true' then real_value = true
							elseif match == 'false' then real_value = false
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
					match = text:match('^[@%$]')
					if match then tok_type = TOK.variable end
				end
			elseif curr_scope == '"' or curr_scope == '\'' then
				--Logic for inside strings
				local this_ix = 1
				local this_str = ''
				while true do
					local this_chr = text:sub(this_ix, this_ix)

					if this_chr == '' then
						parse_error(Span:new(line, col + #this_str, line, col + #this_str), 'Unexpected EOF inside string', file)
					end

					--No line breaks are allowed inside strings
					if this_chr == '\n' then
						parse_error(Span:new(line, col + #this_str, line, col + #this_str), 'Unexpected line ending inside string', file)
					end

					--Once string ends, add text to token list and exit string.
					--If we found an expression instead, add to the stack (only in double-quoted strings).
					local next_chr = text:sub(this_ix+1,this_ix+1)
					if this_chr == curr_scope or ((this_chr == '{' or (this_chr == '$' and next_chr == '{')) and curr_scope ~= '\'') then
						if #this_str > 0 then
							--Insert current built string
							text = text:sub(this_ix, #text)
							---@type Token
							local out = {
								span = Span:new(line, col, line, col),
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
							tok_type = TOK.string_close
							table.remove(scopes)
						end

						break
					end

					--Parse escape chars. Only a few have special meaning.
					--Every other "escape" char is just the same character without the backslash.
					if this_chr == '\\' then
						this_ix = this_ix + 1
						this_chr = text:sub(this_ix, this_ix)
						if this_chr == '' then
							parse_error(Span:new(line, col + #this_str, line, col + #this_str), 'Unexpected EOF inside string (after "\\")', file)
						elseif this_chr == 'n' then
							this_chr = '\n'
						elseif this_chr == 't' then
							this_chr = '\t'
						elseif this_chr == 's' then
							this_chr = ' ' --non-breaking space
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

					if match ~= ';' then
						line = line + 1
						col = 0
					end
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
				col = col + #match
				text = text:sub(#match+1, #text)
				if not tok_ignore then
					---@type Token
					return {
						span = Span:new(line, col - #match, line, col - #match),
						text = match,
						id = tok_type,
						value = real_value,
					}
				end
			else
				parse_error(Span:new(line, col, line, col), 'Unexpected character "'..text:sub(1,1)..'"', file)
			end
		end

		--Make sure all strings, parens, and brackets all match up.
		local remaining_scope = scopes[#scopes]
		if remaining_scope == '"' or remaining_scope == '\'' then
			parse_error(Span:new(line, col, line, col), 'Unexpected EOF inside string', file)
		elseif remaining_scope == '(' then
			parse_error(Span:new(line, col, line, col), 'Missing parenthesis, expected ")"', file)
		elseif remaining_scope == '[' then
			parse_error(Span:new(line, col, line, col), 'Missing bracket, expected "]"', file)
		elseif remaining_scope == '{' then
			parse_error(Span:new(line, col, line, col), 'Missing brace after expression, expected "}"', file)
		elseif remaining_scope == '$' then
			parse_error(Span:new(line, col, line, col), 'Missing brace after command eval, expected "}"', file)
		end
	end

	return token_iterator
end
