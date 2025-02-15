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
	--- @param output_file string The output file path.
	--- @return boolean success Whether the compilation was successful.
	compile = function(program_text, output_file)
		local c_code = [[
		#define LUA_IMPL
		#include "minilua.h"
		int main() {
			lua_State *L = luaL_newstate();
			luaL_openlibs(L);
			luaL_loadstring(L, "]] .. program_text:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. [[");
			lua_pcall(L, 0, 0, 0);
			lua_close(L);
			return 0;
		}
		]]

		local c_file = FS.open_lib('main.c', 'wb')
		if not c_file then
			error('Failed to open file for writing.')
		end

		c_file:write(c_code)
		c_file:close()

		local cc = 'gcc'
		local command = cc .. ' -o ' .. output_file .. ' ' .. FS.libs_dir .. 'main.c -lm'

		io.stderr:write(command .. '\n')

		local result = os.execute(command)

		os.remove(FS.libs_dir .. 'main.c')

		return result == 0
	end,
}
