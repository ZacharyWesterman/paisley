--[[
	Methods:
		XML.parse(text) to parse an XML string into data.
		XML.stringify(data) to convert data into an XML string.
--]]

XML = {
	---@brief Table of tags that do not require an end tag.
	no_end_tag = {
		br = true,
		hr = true,
		img = true,
		input = true,
		link = true,
		meta = true,
		area = true,
		base = true,
		col = true,
		command = true,
		embed = true,
		keygen = true,
		param = true,
		source = true,
		track = true,
		wbr = true,
	},

	---@brief Parse XML text into a table.
	---This function will never error, even if the XML is invalid.
	---@param text string The XML text to parse.
	---@return table ast The abstract syntax tree of the XML.
	parse = function(text)
		local tok = {
			tag_open = 0,
			tag_close = 1,
			tag_type = 3,
			tag_attr = 4,
			tag_value = 5,
			equal = 6,
			text = 7,
		}

		--Split the text into tokens (efficiently)
		local function tokenize(text)
			local in_tag = false
			local found_tag_type = false
			local tag_attr_type = tok.tag_attr

			return function()
				while #text > 0 do
					if in_tag then
						--Tag end
						if text:sub(1, 1) == ">" then
							text = text:sub(2)
							in_tag = false
							return tok.tag_close, ">"
						end

						--Self-closing tag end
						local m = text:match("^/%s*>")
						if m then
							text = text:sub(#m + 1)
							in_tag = false
							return tok.tag_close, "/>"
						end

						if not found_tag_type then
							--Tag name
							m = text:match("^[^%s=/>\"]+")
							if m then
								text = text:sub(#m + 1)
								found_tag_type = true
								return tok.tag_type, m
							end
						else
							--Double-quoted attribute value
							m = text:match("^\"[^\"]*\"")
							if m then
								text = text:sub(#m + 1)
								local attr_type = tag_attr_type
								tag_attr_type = tok.tag_attr
								return attr_type, m:sub(2, #m - 1)
							end

							--Single-quoted attribute value
							m = text:match("^\'[^\']*\'")
							if m then
								text = text:sub(#m + 1)
								local attr_type = tag_attr_type
								tag_attr_type = tok.tag_attr
								return attr_type, m:sub(2, #m - 1)
							end

							--Attribute or attribute value
							m = text:match("^[^%s=/>\"]+")
							if m then
								text = text:sub(#m + 1)
								local attr_type = tag_attr_type
								tag_attr_type = tok.tag_attr
								return attr_type, m
							end

							--Attribute value marker
							if text:sub(1, 1) == "=" then
								text = text:sub(2)
								tag_attr_type = tok.tag_value
								-- Ignore the equal sign
							end

							--Slash without closing tag
							if text:sub(1, 1) == "/" then
								text = text:sub(2)
								return tok.text, "/"
							end
						end

						--Whitespace
						m = text:match("^%s+")
						if m then
							text = text:sub(#m + 1)
							--Ignore white space
						end
					else
						--Close tag start
						local m = text:match("^<%s*/")
						if m then
							text = text:sub(#m + 1)
							in_tag = true
							found_tag_type = false
							tag_attr_type = tok.tag_attr
							return tok.tag_open, "</"
						end

						--Open tag start
						if text:sub(1, 1) == "<" then
							text = text:sub(2)
							in_tag = true
							found_tag_type = false
							tag_attr_type = tok.tag_attr
							return tok.tag_open, "<"
						end

						--Plain text
						m = text:match("^[^<]+")
						if m then
							text = text:sub(#m + 1)

							--Remove leading and trailing whitespace
							m = m:gsub("^%s+", ""):gsub("%s+$", "")
							--Normalize whitespace
							m = m:gsub("[\n\r\x0b\t ]+", " ")
							--Replace HTML entities
							m = m:gsub("&lt;", "<")
								:gsub("&gt;", ">")
								:gsub("&quot;", "\"")
								:gsub("&apos;", "'")
								:gsub("&nbsp;", " ")
								:gsub("&amp;", "&")

							return tok.text, m
						end
					end
				end

				if in_tag then
					in_tag = false
					return tok.tag_close, ""
				end
			end
		end

		--Parse the tokens into a list of entities
		local stack = setmetatable({}, { is_array = true })
		for id, text in tokenize(text) do
			if id == tok.text then
				--Push the text onto the stack
				table.insert(stack, setmetatable({
					type = "text",
					value = text,
				}, { is_array = false }))
			elseif id == tok.tag_value then
				--Set the value of the last tag on the stack
				local t = stack[#stack]
				t.value = text
			elseif id == tok.tag_close then
				--Pop the stack until tag_open is found, creating the tag as a table
				local tag = {
					attributes = setmetatable({}, { is_array = false }),
					children = setmetatable({}, { is_array = true }),
				}
				local tag_meta = { is_array = false }

				while #stack > 0 do
					local t = table.remove(stack)
					local meta = getmetatable(t) or {}

					if meta.id == tok.tag_open then
						if meta.text == "</" then tag_meta.close = true end
						break
					end

					if meta.id == tok.tag_type then
						tag.type = meta.text
					elseif meta.text == 'type' or meta.text == 'children' or meta.text == 'attributes' then
						tag.attributes[meta.text] = t.value or ""
					else
						tag[meta.text] = t.value or ""
					end
				end

				if text ~= "/>" and not tag.close then tag_meta.open = true end

				if XML.no_end_tag[tag.type] then
					tag_meta.close = false
					tag_meta.open = false
				end

				setmetatable(tag, tag_meta)
				table.insert(stack, tag)
			else
				--Push the token onto the stack
				local t = {}
				local meta = { id = id, text = text }
				setmetatable(t, meta)
				table.insert(stack, t)
			end
		end

		--Build the tree from the stack
		local function pop_until(tag_type)
			local result = setmetatable({}, { is_array = true })
			local tag;

			while #stack > 0 do
				local t = table.remove(stack)
				local meta = getmetatable(t) or {}

				if meta.close then
					local children, open_tag = pop_until(t.type)
					open_tag.children = children
					t = open_tag
				elseif meta.open and t.type == tag_type then
					tag = t;
					break
				end

				table.insert(result, t)
			end

			--Reverse the order of the children
			for i = 1, #result / 2 do
				result[i], result[#result - i + 1] = result[#result - i + 1], result[i]
			end

			return result, tag
		end
		local ast = pop_until()

		return ast
	end,

	---@brief Convert a table into XML text.
	---This function will never error, even if the AST is invalid.
	---@param ast table The abstract syntax tree of the XML.
	---@return string text The XML text.
	stringify = function(ast, pretty)
		local function stringify_recursive(t, indent)
			indent = indent or 0

			local str = (" "):rep(indent)

			if type(t) ~= "table" then
				return str .. tostring(t)
			end

			if t.type == "text" then
				--Replace xml entities
				return str .. t.value:gsub("&", "&amp;")
					:gsub("<", "&lt;")
					:gsub(">", "&gt;")
					:gsub("\"", "&quot;")
					:gsub("'", "&apos;")
					:gsub(" ", "&nbsp;")
			end

			str = str .. ("<%s"):format(t.type)
			if type(t.attributes) == "table" then
				for k, v in pairs(t.attributes) do
					str = str .. (" %s=\"%s\""):format(k, v)
				end
			end
			for k, v in pairs(t) do
				if k ~= "type" and k ~= "attributes" and k ~= "children" then
					str = str .. (" %s=\"%s\""):format(k, v)
				end
			end

			if XML.no_end_tag[t.type] then
				return str .. "/>"
			end

			str = str .. ">"

			if type(t.children) == "table" then
				for i = 1, #t.children do
					str = str .. ("%s\n"):format((" "):rep(indent + 2))
					str = str .. stringify_recursive(t.children[i], indent + 2)
				end
				if #t.children > 0 then str = str .. ("\n%s"):format((" "):rep(indent)) end
			end

			str = str .. ("</%s>"):format(t.type)

			return str
		end

		if type(ast) ~= "table" then
			return tostring(ast)
		end

		local result = ""
		for i = 1, #ast do
			if i > 1 then result = result .. "\n" end
			result = result .. stringify_recursive(ast[i])
		end
		return result
	end,
}
