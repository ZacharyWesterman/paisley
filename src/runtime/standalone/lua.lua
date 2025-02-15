---@diagnostic disable-next-line
STANDALONE.lua = {
	--- Generate a standalone Lua program from a given Paisley bytecode.
	--- which can be run without the need for the Paisley interpreter.
	--- @param bytecode table Paisley bytecode.
	--- @return string program_text The generated Lua program.
	generate = function(bytecode)
		require 'src.meta.lua'

		local init = [[
		V4 = os.time()
		V8 = 1000000000000
		PGM_ARGS = arg
		V1 = "]] .. json.stringify(bytecode):
		gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'

		local prefix = FS.open('src/util/output_pc.lua', true):read('*all')
		local text = FS.open('src/runtime.lua', true):read('*all')
		local postfix = [[
		while true do
			RUN()
			if not INSTRUCTIONS[CURRENT_INSTRUCTION] then break end
		end
		]]

		text = init .. '\n' .. prefix .. '\n' .. text .. '\n' .. postfix

		text = LUA.minify(text, true)

		return text
	end,

	--- Compile a standalone Lua program into a binary executable.
	--- @param program_text string The Lua program text.
	--- @return string binary The compiled binary.
	compile = function(program_text)
		error('COMPILER ERROR: Lua binary compilation is not implemented!')
	end,
}
