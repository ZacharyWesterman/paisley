--[[
	Methods:
		json.parse(text) to parse a JSON string into data.
		json.stringify(data, [indent]) to convert data into a JSON string. Text will only be pretty-printed if indent is specified.
--]]


json = {
	---Convert arbitrary data into a JSON string representation.
	---Will error if data is something that cannot be serialized, such as a function, userdata or thread.
	---@param data any The data to serialize.
	---@param indent integer|nil The number of spaces to indent on each scope change.
	---@param return_error boolean|nil If true, return the error as a second parameter. Otherwise halts program execution on error.
	---@return string, string|nil
	stringify = function(data, indent, return_error)
		local function __stringify(data, indent, __indent)
			local tp = type(data)

			if tp == 'table' then
				local next_indent

				if indent ~= nil then
					if __indent == nil then __indent = 0 end
					next_indent = indent + __indent
				end

				--Check if a table is an array or an object
				local is_array = true
				local meta = getmetatable(data)
				if meta and meta.is_array ~= nil then
					is_array = meta.is_array
				else
					for key, value in pairs(data) do
						if type(key) ~= 'number' then
							is_array = false
							break
						end
					end
				end

				local result = ''
				if is_array then
					if indent ~= nil then result = '[\n' else result = '[' end
					for key=1, #data do
						local str = __stringify(data[key], indent, next_indent)
						if key ~= #data then str = str .. ',' end
						if indent ~= nil then
							result = result .. (' '):rep(next_indent) .. str .. '\n'
						else
							result = result .. str
						end
					end
					if indent ~= nil then return result .. (' '):rep(__indent) .. ']' else return result .. ']' end
				else
					if indent ~= nil then result = '{\n' else result = '{' end
					local ct = 0
					for key, value in pairs(data) do
						local str = __stringify(tostring(key), indent, next_indent) .. ':' .. __stringify(value, indent, next_indent)
						if indent ~= nil then
							if ct > 0 then result = result .. ',\n' end
							result = result .. (' '):rep(next_indent) .. str
						else
							if ct > 0 then result = result .. ',' end
							result = result .. str
						end
						ct = ct + 1
					end
					if indent ~= nil then return result .. (' '):rep(__indent) .. '\n}' else return result .. '}' end
				end

			elseif tp == 'string' then
				local repl_chars = {
					{'\\', '\\\\'},
					{'\"', '\\"'},
					{'\n', '\\n'},
					{'\t', '\\t'},
				}
				local result = data
				local i
				for i=1, #repl_chars do
					result = result:gsub(repl_chars[i][1], repl_chars[i][2])
				end
				return '"' .. result .. '"'
			elseif tp == 'number' then
				return tostring(data)
			elseif data == true then
				return 'true'
			elseif data == false then
				return 'false'
			elseif data == nil then
				return 'null'
			else
				local msg = 'Unable to stringify data "'..tostring(data)..'" of type '..tp..'.'
				if return_error then
					return '', msg
				else
					error(msg)
				end
			end
		end

		return __stringify(data, indent)
	end,

	---Parse a JSON string representation into arbitrary data.
	---Will error if the JSON string is invalid.
	---@param text string The JSON string to parse.
	---@param return_error boolean|nil If true, return the error as a second parameter. Otherwise halts program execution on error.
	---@return any, string|nil
	parse = function(text, return_error)
		local line = 1
		local col = 1
		local tokens = {}

		local _tok = {
			literal = 0,
			comma = 1,
			colon = 2,
			lbrace = 3,
			rbrace = 4,
			lbracket = 5,
			rbracket = 6,
		}

		local newtoken = function(value, kind)
			return {
				value=value,
				kind=kind,
				line=line,
				col=col,
			}
		end

		local do_error = function(msg)
			error('JSON parse error at ['..line..':'..col..']: '..msg)
		end

		if return_error then
			do_error = function(msg)
				return nil, 'JSON parse error at ['..line..':'..col..']: '..msg
			end
		end

		--Split JSON string into tokens
		local in_string = false
		local escaped = false
		local i = 1
		local this_token = ''
		local paren_stack = {}
		while i <= #text do
			local chr = text:sub(i,i)

			col = col + 1
			if chr == '\n' then
				line = line + 1
				col = 0
				if in_string then
					return do_error('Unexpected line ending inside string.')
				end
			elseif in_string then
				if escaped then
					if chr == 'n' then chr = '\n' end
					if chr == 't' then chr = '\t' end
					this_token = this_token .. chr
					escaped = false
				elseif chr == '\\' then
					escaped = true
					-- this_token = this_token .. chr
				elseif chr == '"' then
					--End string, append token
					table.insert(tokens, newtoken(this_token, _tok.literal))
					this_token = ''
					in_string = false
				else
					this_token = this_token .. chr
				end
			elseif chr == '[' then
				table.insert(tokens, newtoken(chr, _tok.lbracket))
				table.insert(paren_stack, chr)
			elseif chr == ']' then
				table.insert(tokens, newtoken(chr, _tok.rbracket))
				if #paren_stack == 0 then return do_error('Unexpected closing bracket "]".') end
				if table.remove(paren_stack) ~= '[' then return do_error('Bracket mismatch (expected "}", got "]").') end
			elseif chr == '{' then
				table.insert(tokens, newtoken(chr, _tok.lbrace))
				table.insert(paren_stack, chr)
			elseif chr == '}' then
				table.insert(tokens, newtoken(chr, _tok.rbrace))
				if #paren_stack == 0 then return do_error('Unexpected closing brace "}".') end
				if table.remove(paren_stack) ~= '{' then return do_error('Brace mismatch (expected "]", got "}").') end
			elseif chr == ':' then
				table.insert(tokens, newtoken(chr, _tok.colon))
			elseif chr == ',' then
				table.insert(tokens, newtoken(chr, _tok.comma))
			elseif chr:match('%s') then
				--Ignore white space outside of strings
			elseif chr == '"' then
				--Start a string token
				in_string = true
			elseif chr == 't' and text:sub(i, i+3) == 'true' then
				table.insert(tokens, newtoken(true, _tok.literal))
				i = i + 3
			elseif chr == 'f' and text:sub(i, i+4) == 'false' then
				table.insert(tokens, newtoken(false, _tok.literal))
				i = i + 4
			elseif chr == 'n' and text:sub(i, i+3) == 'null' then
				table.insert(tokens, newtoken(nil, _tok.literal))
				i = i + 3
			else
				local num = text:match('^%-?%d+%.?%d*', i)
				if num == nil then
					return do_error('Invalid character "'..chr..'".')
				else
					table.insert(tokens, newtoken(tonumber(num), _tok.literal))
					i = i + #num - 1
				end
			end

			i = i + 1 --Next char
		end

		if in_string then
			col = col - #this_token
			return do_error('Unterminated string.')
		end

		if #paren_stack > 0 then
			local last = table.remove(paren_stack)
			if last == '[' then
				return do_error('No terminating "]" bracket.')
			else
				return do_error('No terminating "}" brace.')
			end
		end

		local lex_error = function(token, msg)
			line = token.line
			col = token.col
			local r1, r2 = do_error(msg)
			return r1, nil, r2
		end

		--Now that the JSON data is confirmed to only have valid tokens, condense the tokens into valid data
		--Note that at this point, braces are guaranteed to be in the right order and matching open/close braces.
		local function lex(i)
			local this_object
			local this_token = tokens[i]

			if this_token.kind == _tok.literal then
				return this_token.value, i
			elseif this_token.kind == _tok.lbracket then
				--Generate array-like tables
				this_object = setmetatable({}, {is_array = true})
				i = i + 1
				this_token = tokens[i]

				while this_token.kind ~= _tok.rbracket do
					local value
					value, i = lex(i)
					table.insert(this_object, value)
					this_token = tokens[i+1]
					if this_token.kind == _tok.comma then
						i = i + 1
					elseif this_token.kind ~= _tok.rbracket then
						return lex_error(this_token, 'Unexpected token "'..this_token.value..'" (expected "," or "]").')
					end
					i = i + 1
					this_token = tokens[i]
				end
				return this_object, i
			elseif this_token.kind == _tok.lbrace then
				--Generate object-like tables
				this_object = setmetatable({}, {is_array = false})
				i = i + 1
				this_token = tokens[i]

				while this_token.kind ~= _tok.rbrace do
					--Only exact keys are allowed‚ no objects as keys
					if this_token.kind ~= _tok.literal then
						return lex_error(this_token, 'Unexpected token "'..this_token.value..'" (expected literal).')
					end
					local key = this_token.value

					this_token = tokens[i+1]
					if this_token.kind ~= _tok.colon then
						return lex_error(this_token, 'Unexpected token "'..this_token.value..'" (expected ":").')
					end

					this_object[key], i = lex(i+2)
					this_token = tokens[i+1]
					if this_token.kind == _tok.comma then
						i = i + 1
					elseif this_token.kind ~= _tok.rbrace then
						return lex_error(this_token, 'Unexpected token "'..this_token.value..'" (expected "," or "}").')
					end
					i = i + 1
					this_token = tokens[i]
				end
				return this_object, i
			else
				return lex_error(this_token, 'Unexpected token "'..this_token.value..'".')
			end
		end

		if #tokens == 0 then return nil end
		local r1, r2, r3 = lex(1)
		return r1, r3
	end,


	---Check if a JSON string is valid.
	---Returns false and a descriptive error message if the text contains invalid JSON, or true if valid.
	---@param text string The JSON string to parse.
	---@return boolean, string|nil
	verify = function(text)
		local res, err = json.parse(text, true)
		if err ~= nil then
			return false, err
		end
		return true
	end,
}
