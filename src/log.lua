return {
	error = function(msg, endl)
		--[[minify-delete]]
		if true then
			io.stderr:write('[\27[0;31mERROR\27[0m]: ' .. (msg or ''))
			if endl ~= false then io.stderr:write('\n') end
			return
		end
		--[[/minify-delete]]
		print('[ERROR]: ' .. (msg or ''))
	end,

	warn = function(msg, endl)
		--[[minify-delete]]
		if true then
			io.stderr:write('[\27[0;33mWARNING\27[0m]: ' .. (msg or ''))
			if endl ~= false then io.stderr:write('\n') end
			return
		end
		--[[/minify-delete]]
		print('[WARNING]: ' .. (msg or ''))
	end,

	info = function(msg, endl)
		--[[minify-delete]]
		if true then
			io.stderr:write('[\27[0;34mINFO\27[0m]: ' .. (msg or ''))
			if endl ~= false then io.stderr:write('\n') end
			return
		end
		--[[/minify-delete]]
		print('[INFO]: ' .. (msg or ''))
	end,

	--[[minify-delete]]
	context = function(span, filename, header_msg)
		local fp = io.open(filename, 'r')

		--Just do nothing if we can't read the file
		if not fp then return end
		for i = 1, span.from.line - 1 do
			local text = fp:read('l')
			--If context is out of range of the file, just do nothing.
			if not text then return end
		end

		if header_msg then
			io.stderr:write('[\27[0;34mCONTEXT\27[0m]: ')
			io.stderr:write('\27[0;34m' .. header_msg .. '\27[0m:\n')
		end

		for i = span.from.line, span.to.line do
			local text = fp:read('l')
			if not text then break end
			text = text:gsub('\t', ' ')

			io.stderr:write('[\27[0;34mCONTEXT\27[0m]: ')

			local from_col, to_col = 1, #text
			if i == span.from.line then
				from_col = span.from.col
			end
			if i == span.to.line then
				to_col = span.to.col
			end

			--Highlight the context
			io.stderr:write(text:sub(1, from_col))
			io.stderr:write('\27[36m' .. text:sub(from_col + 1, to_col) .. '\27[0m')
			io.stderr:write(text:sub(to_col + 1, #text))
			io.stderr:write('\n')
		end

		if span.from.line == span.to.line and span.from.col >= 0 then
			io.stderr:write('[\27[0;34mCONTEXT\27[0m]: ' ..
				(' '):rep(span.from.col) .. '\27[36m' .. ('^'):rep(span.to.col - span.from.col) .. '\27[0m\n')
		end
	end,
	--[[/minify-delete]]
}
