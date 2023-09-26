tok = {
	text = 0,

	kwd_for = 1,
	kwd_while = 2,
	kwd_in = 3,
	kwd_do = 4,
	kwd_if = 5,
	kwd_then = 6,
	kwd_elif = 7,
	kwd_else = 8,
	kwd_end = 9,
	kwd_continue = 10,
	kwd_break = 11,
	kwd_delete = 12,
	kwd_do = 13,
	kwd_goto = 14,
	kwd_gosub = 15,
	kwd_return = 16,
	kwd_let = 17,

	expr_open = 18,
	expr_close = 19,
	variable = 20,

	op_plus = 21,
	op_minus = 22,
	op_times = 23,
	op_idiv = 24,
	op_div = 25,
	op_mod = 26,
	op_slice = 27,
	op_count = 28,
	op_length = 29,
	op_not = 30,
	op_and = 31,
	op_or = 32,
	op_xor = 33,
	op_in = 34,
	op_exists = 35,
	op_like = 36,
	op_ge = 37,
	op_gt = 38,
	op_le = 39,
	op_lt = 40,
	op_eq = 41,
	op_ne = 42,

	paren_open = 43,
	paren_close = 44,

	lit_true = 45,
	lit_false = 46,
	lit_null = 47,

	string_open = 48,
	string_close = 49,
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

function lex(text, file)
	local tokens = {}
	local line = 1
	local col = 1
	local scopes = {}

	while #text > 0 do
		local match = nil
		local tok_type = nil
		local tok_ignore = false
		local curr_scope = scopes[#scopes]

		if curr_scope == nil then
			--Default parse rules

			--line ending
			match = text:match('^[\n\x0b]')
			if match then
				tok_ignore = true
				line = line + 1
				col = 0
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
				match = text:match('^[^ \t\n\r"\'{}\x0b;]+')
				if match then tok_type = tok.text end
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
				if this_chr == curr_scope or this_chr == '{' then
					if #this_str > 0 then
						--Insert current built string
						text = text:sub(this_ix, #text)
						table.insert(tokens, {
							text = this_str,
							id = tok.text,
							line = line,
							col = col,
						})
						col = col + #this_str
						print(this_str..' -> '..tok.text)
					end

					match = this_chr
					if this_chr == '{' then
						--enter expression (add to scope stack)
						tok_type = tok.expr_open
						table.insert(scopes, match)
					else
						--exit string (pop to previous scope)
						tok_type = tok.string_close
						table.remove(scopes)
					end

					break
				end

				--Parse escape chars. Currently only 2 of them, don't see much need to add more.
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
				table.insert(tokens, {
					text = match,
					id = tok_type,
					line = line,
					col = col,
				})
				print(match..' -> '..tok_type)
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
	end
end

lex('{')