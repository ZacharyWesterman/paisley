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
		--[[minify-delete]]
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
		--[[minify-delete]]
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
		--[[minify-delete]]
	end,
}
