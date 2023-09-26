_tok_i = -1
function k()
	_tok_i = _tok_i + 1
	return _tok_i
end

tok = {
	text = k(),

	kwd_for = k(),
	kwd_while = k(),
	kwd_in = k(),
	kwd_do = k(),
	kwd_if = k(),
	kwd_then = k(),
	kwd_elif = k(),
	kwd_else = k(),
	kwd_end = k(),
	kwd_continue = k(),
	kwd_break = k(),
	kwd_delete = k(),
	kwd_do = k(),
	kwd_goto = k(),
	kwd_gosub = k(),
	kwd_return = k(),
	kwd_let = k(),
	kwd_stop = k(),

	expr_open = k(),
	expr_close = k(),
	variable = k(),

	op_plus = k(),
	op_minus = k(),
	op_times = k(),
	op_idiv = k(),
	op_div = k(),
	op_mod = k(),
	op_slice = k(),
	op_count = k(),
	op_length = k(),
	op_not = k(),
	op_and = k(),
	op_or = k(),
	op_xor = k(),
	op_in = k(),
	op_exists = k(),
	op_like = k(),
	op_ge = k(),
	op_gt = k(),
	op_le = k(),
	op_lt = k(),
	op_eq = k(),
	op_ne = k(),

	paren_open = k(),
	paren_close = k(),

	lit_true = k(),
	lit_false = k(),
	lit_null = k(),

	string_open = k(),
	string_close = k(),

	label = k(),
	command_open = k(),
	command_close = k(),

	line_ending = k(),
}

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
	['goto'] = tok.kwd_goto,
	['gosub'] = tok.kwd_gosub,
	['return'] = tok.kwd_return,
	['let'] = tok.kwd_let,
	['stop'] = tok.kwd_stop,
}

opers = {
	['+'] = tok.op_plus,
	['-'] = tok.op_minus,
	['*'] = tok.op_times,
	['//'] = tok.op_idiv,
	['/'] = tok.op_div,
	['%'] = tok.op_mod,
	[':'] = tok.op_slice,
	['#'] = tok.op_count,
	['$'] = tok.op_length,
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
}

literals = {
	['true'] = tok.lit_true,
	['false'] = tok.lit_false,
	['null'] = tok.lit_null,
}


function parse_error(line, col, msg, file)
	if file ~= nil then
		error(file..': '..line..', '..col..': '..msg)
	else
		error(line..', '..col..': '..msg)
	end
end

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
function lex(text --[[string]], file --[[string | nil]])
	local line = 1
	local col = 1
	local scopes = {}

	local function token_iterator()
		while #text > 0 do
			local match = nil
			local tok_type = nil
			local tok_ignore = false
			local curr_scope = scopes[#scopes]

			if curr_scope == nil or curr_scope == '$' then
				--Default parse rules

				--line endings (separate individual commands)
				match = text:match('^[\n\x0b;]')
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
						end
					end
				end

				--non-quoted text
				if not match then
					match = text:match('^[^ \t\n\r"\'{}\x0b;$]+')
					if match then tok_type = tok.text end
				end

				--labels
				if not match then
					match = text:match('^%w+:')
					if match then tok_type = tok.label end
				end

			elseif curr_scope == '{' or curr_scope == '(' then
				--Parse rules when inside expressions

				--line endings cause errors inside expressions
				match = text:match('^[\n\x0b]')
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

				--expression start
				if not match then
					match = text:match('^{')
					if match then
						tok_type = tok.expr_open
						table.insert(scopes, match)
					end
				end

				--expression end
				if not match then
					match = text:match('^}')
					if match then
						tok_type = tok.expr_close
						table.remove(scopes)
						if curr_scope ~= '{' then parse_error(line, col, 'Mismatched parentheses, expected ")", got "}"', file) end
					end
				end

				--paren close
				if not match then
					match = text:match('^%)')
					if match then
						tok_type = tok.paren_close
						table.remove(scopes)
						if curr_scope ~= '(' then parse_error(line, col, 'Mismatched parentheses, expected "}", got ")"', file) end
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

				--inline command start
				if not match then
					match = text:match('^%${')
					if match then
						tok_type = tok.command_open
						table.insert(scopes, '$')
					end
				end

				--Operators
				if not match then
					local key
					local value
					for key, value in pairs(opers) do
						if (text:sub(1, #key) == key) and not text:sub(#key,#key+1):match('^%w%w') then
							match = key
							tok_type = value
						end
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
						end
					end
				end

				--Variable references
				if not match then
					match = text:match('^%w+')
					if match then tok_type = tok.variable end
				end

				--Special "list of vars" variable
				if not match then
					match = text:match('^@')
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
					if this_chr == '\n' or this_chr == '\x0b' then
						parse_error(line, col + #this_str, 'Unexpected line ending inside string', file)
					end

					--Once string ends, add text to token list and exit string.
					--If we found an expression instead, add to the stack.
					if this_chr == curr_scope or this_chr == '{' or this_chr == '$' then
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
		elseif remaining_scope == '{' then
			parse_error(line, col, 'Unexpected EOF inside expression, expected "}"', file)
		elseif remaining_scope == '$' then
			parse_error(line, col, 'Unexpected EOF inside command eval, expected "}"', file)
		end
	end

	return token_iterator
end


function print_token(token)
	local key
	local value
	for key, value in pairs(tok) do
		if token.id == value then
			print(('%2d:%2d: %13s = %s'):format(token.line, token.col, key, token.text:gsub('[\n\x0b]', '<newline>')))
			return
		end
	end
	print(('%2d:%2d: ERR:%d = "%s"'):format(token.line, token.col, token.id, token.text))
end

for token in lex('"${3*100}"') do
	print_token(token)
end
