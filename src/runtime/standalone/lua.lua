local json = require "src.shared.json"
local fs = require 'src.util.filesystem'
local log = require 'src.log'

---@diagnostic disable-next-line
STANDALONE.lua = {
	--- Generate a standalone Lua program from a given Paisley bytecode.
	--- which can be run without the need for the Paisley interpreter.
	--- @param bytecode table Paisley bytecode.
	--- @return string program_text The generated Lua program.
	generate = function(bytecode)
		require 'src.meta.lua'

		local init = [[
		VERSION = "]] .. ( --[[@diagnostic disable-line]] VERSION or 'unknown') .. [["
		V4 = os.time()
		V8 = 1000000000000
		V6 = arg
		V1 = "]] .. json.stringify(bytecode):
		gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'

		local prefix = --[[build-replace=src/util/output_pc.lua]] fs.open('src/util/output_pc.lua', true):read('*all') --[[/build-replace]]
		local text = --[[build-replace=src/runtime.lua]] fs.open('src/runtime.lua', true):read('*all') --[[/build-replace]]
		local postfix = [[
		while true do
			RUN()
			if not INSTRUCTIONS[CURRENT_INSTRUCTION] then break end
		end
		]]

		text = init .. '\n' .. prefix .. '\n' .. text .. '\n' .. postfix

		text = LUA.minify(text, true, _G['SANDBOX'] or false)

		return text
	end,

	--- Compile a standalone Lua program into a Lua script.
	--- @param program_text string The Lua program text.
	--- @param output_file string The output file path.
	--- @return boolean success Whether the compilation was successful.
	compile = function(program_text, output_file)
		local file = io.open(output_file, 'w')
		if not file then
			log.error('Failed to open `' .. output_file .. '` for writing.')
			os.exit(1)
		end

		file:write('#!/usr/bin/env lua\n')
		file:write(program_text)
		file:close()

		local result = os.execute('chmod +x ' .. output_file)

		return result or false
	end,
}
