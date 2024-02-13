require "src.compiler.tokens"

kwds = {
	['for'] = tok.kwd_for,
	['while'] = tok.kwd_while,
	['in'] = tok.kwd_in,
	['do'] = tok.kwd_do,
	['if'] = tok.kwd_if,
	['then'] = tok.kwd_then,
	['elif'] = tok.kwd_elif,
	['else'] = tok.kwd_else,
	['end'] = tok.kwd_end,
	['continue'] = tok.kwd_continue,
	['break'] = tok.kwd_break,
	['delete'] = tok.kwd_delete,
	['subroutine'] = tok.kwd_subroutine,
	['gosub'] = tok.kwd_gosub,
	['return'] = tok.kwd_return,
	['let'] = tok.kwd_let,
	['stop'] = tok.kwd_stop,
}

opers = {
	['for'] = tok.kwd_for_expr,
	['if'] = tok.kwd_if_expr,
	['else'] = tok.kwd_else_expr,
	['+'] = tok.op_plus,
	['-'] = tok.op_minus,
	['*'] = tok.op_times,
	['//'] = tok.op_idiv,
	['/'] = tok.op_div,
	['%'] = tok.op_mod,
	[':'] = tok.op_slice,
	['#'] = tok.op_count,
	['not'] = tok.op_not,
	['and'] = tok.op_and,
	['or'] = tok.op_or,
	['xor'] = tok.op_xor,
	['in'] = tok.op_in,
	['exists'] = tok.op_exists,
	['like'] = tok.op_like,
	['>='] = tok.op_ge,
	['>'] = tok.op_gt,
	['<='] = tok.op_le,
	['<'] = tok.op_lt,
	['=='] = tok.op_eq,
	['='] = tok.op_eq,
	['~='] = tok.op_ne,
	['!='] = tok.op_ne,
	[','] = tok.op_comma,
	['.'] = tok.op_dot,
}

oper_block = {
	['/'] = '/',
	['>'] = '=',
	['<'] = '=',
	['='] = '=',
}

literals = {
	['true'] = tok.lit_boolean,
	['false'] = tok.lit_boolean,
	['null'] = tok.lit_null,
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
function Lexer(text --[[string]], file --[[string | nil]])
	local line = 1
	local col = 1
	local scopes = {}
	local var_assignment = false

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
			parse_error(line, col, 'Mismatched parentheses, expected "'..expected[last_paren]..'", got "'..this_paren..'"', file)
		end
	end

	local function token_iterator()
		while #text > 0 do
			local match = nil
			local tok_type = nil
			local tok_ignore = false
			local curr_scope = scopes[#scopes]
			local real_value = nil

			if curr_scope == nil or curr_scope == '$' then
				--Default parse rules

				--line endings (separate individual commands)
				match = text:match('^[\n;]')
				if match then
					tok_type = tok.line_ending

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
						tok_type = tok.string_open
						table.insert(scopes, match)
					end
				end

				--expression start
				if not match then
					match = text:match('^{')
					if match then
						tok_type = tok.expr_open
						table.insert(scopes, match)
					end
				end

				--inline command start
				if not match then
					match = text:match('^%${')
					if match then
						tok_type = tok.command_open
						table.insert(scopes, '$')
					end
				end

				--inline command end
				if not match and curr_scope == '$' then
					match = text:match('^}')
					if match then
						tok_type = tok.command_close
						table.remove(scopes)
					end
				end

				--keywords
				if not match then
					local key
					local value
					for key, value in pairs(kwds) do
						if (text:sub(1, #key) == key) and not text:sub(#key,#key+1):match('^%w%w') then
							match = key
							tok_type = value

							if match == 'let' then
								table.insert(scopes, 'let')
							end
							break
						end
					end
				end

				--non-quoted text
				if not match then
					match = text:match('^[^ \t\n\r"\'{};$]+')
					if match then tok_type = tok.text end
				end

			elseif curr_scope == '{' or curr_scope == '(' or curr_scope == '[' then
				--Parse rules when inside expressions

				--line endings cause errors inside expressions
				match = text:match('^\n')
				if match then
					parse_error(line, col, 'Unexpected line ending inside expression', file)
				end

				--White space
				if not match then
					match = text:match('^[ \t\r]+')
					if match then tok_ignore = true end
				end

				--string start
				if not match then
					match = text:match('^[\'"]')
					if match then
						tok_type = tok.string_open
						table.insert(scopes, match)
					end
				end

				-- --expression start
				-- if not match then
				-- 	match = text:match('^{')
				-- 	if match then
				-- 		tok_type = tok.expr_open
				-- 		table.insert(scopes, match)
				-- 	end
				-- end

				--expression end
				if not match then
					match = text:match('^}')
					if match then
						tok_type = tok.expr_close
						table.remove(scopes)
						check_parens(curr_scope, match)
					end
				end

				--paren close
				if not match then
					match = text:match('^%)')
					if match then
						tok_type = tok.paren_close
						table.remove(scopes)
						check_parens(curr_scope, match)
					end
				end

				--paren open
				if not match then
					match = text:match('^%(')
					if match then
						tok_type = tok.paren_open
						table.insert(scopes, match)
					end
				end

				--bracket close
				if not match then
					match = text:match('^%]')
					if match then
						tok_type = tok.index_close
						table.remove(scopes)
						check_parens(curr_scope, match)
					end
				end

				--bracket open
				if not match then
					match = text:match('^%[')
					if match then
						tok_type = tok.index_open
						table.insert(scopes, match)
					end
				end

				--inline command start
				if not match then
					match = text:match('^%${')
					if match then
						tok_type = tok.command_open
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
							parse_error(line, col, 'Invalid '..tp..'number "'..match..'"', file)
						end
						tok_type = tok.lit_number
						real_value = n
					end
				end

				--Operators
				if not match then
					local key
					local value
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
						tok_type = tok.op_exclamation
					end
				end

				--Named constants
				if not match then
					local key
					local value
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
					if match then tok_type = tok.variable end
				end

				--Special "list of vars" and "list of commands" variables
				if not match then
					match = text:match('^[@%$]')
					if match then tok_type = tok.variable end
				end
			elseif curr_scope == '"' or curr_scope == '\'' then
				--Logic for inside strings
				local this_ix = 1
				local this_str = ''
				while true do
					local this_chr = text:sub(this_ix, this_ix)

					if this_chr == '' then
						parse_error(line, col + #this_str, 'Unexpected EOF inside string', file)
					end

					--No line breaks are allowed inside strings
					if this_chr == '\n' then
						parse_error(line, col + #this_str, 'Unexpected line ending inside string', file)
					end

					--Once string ends, add text to token list and exit string.
					--If we found an expression instead, add to the stack (only in double-quoted strings).
					if this_chr == curr_scope or ((this_chr == '{' or this_chr == '$') and curr_scope ~= '\'') then
						if #this_str > 0 then
							--Insert current built string
							text = text:sub(this_ix, #text)
							local out = {
								text = this_str,
								id = tok.text,
								line = line,
								col = col,
							}
							col = col + #this_str
							return out
						end

						match = this_chr
						if this_chr == '{' then
							--enter expression (add to scope stack)
							tok_type = tok.expr_open
							table.insert(scopes, match)
						elseif this_chr == '$' then
							--Make sure command eval is formatted correctly
							if text:sub(this_ix+1,this_ix+1) ~= '{' then
								parse_error(line, col, 'Found command marker but no body (expected "{")', file)
							end
							match = '${'

							--enter inline command eval
							tok_type = tok.command_open
							table.insert(scopes, this_chr)
						else
							--exit string (pop to previous scope)
							tok_type = tok.string_close
							table.remove(scopes)
						end

						break
					end

					--Parse escape chars. Currently only 2 of them, don't see much need to add more.
					--Every other "escape" char is just the same character without the backslash.
					if this_chr == '\\' then
						this_ix = this_ix + 1
						this_chr = text:sub(this_ix, this_ix)
						if this_chr == '' then
							parse_error(line, col + #this_str, 'Unexpected EOF inside string (after "\\")', file)
						elseif this_chr == 'n' then
							this_chr = '\n'
						elseif this_chr == 't' then
							this_chr = '\t'
						end
					end

					this_str = this_str .. this_chr
					this_ix = this_ix + 1
				end

			elseif curr_scope == 'let' then
				--line endings (end of variable declaration)
				match = text:match('^[\n;]')
				if match then
					tok_type = tok.line_ending

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
						tok_type = tok.op_assign
						table.remove(scopes)
					end
				end

				--expression start indicates that we're setting a sub-value of the variable
				if not match then
					match = text:match('^{')
					if match then
						tok_type = tok.expr_open
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
					if match then tok_type = tok.var_assign end
				end
			end

			--Append currently matched token to token list
			if match then
				col = col + #match
				text = text:sub(#match+1, #text)
				if not tok_ignore then
					return {
						text = match,
						id = tok_type,
						line = line,
						col = col - #match,
						value = real_value,
					}
				end
			else
				parse_error(line, col, 'Unexpected character "'..text:sub(1,1)..'"', file)
			end
		end

		--Make sure all strings, parens, and brackets all match up.
		local remaining_scope = scopes[#scopes]
		if remaining_scope == '"' or remaining_scope == '\'' then
			parse_error(line, col, 'Unexpected EOF inside string', file)
		elseif remaining_scope == '(' then
			parse_error(line, col, 'Missing parenthesis, expected ")"', file)
		elseif remaining_scope == '[' then
			parse_error(line, col, 'Missing bracket, expected "]"', file)
		elseif remaining_scope == '{' then
			parse_error(line, col, 'Missing brace after expression, expected "}"', file)
		elseif remaining_scope == '$' then
			parse_error(line, col, 'Missing brace after command eval, expected "}"', file)
		end
	end

	return token_iterator
end
