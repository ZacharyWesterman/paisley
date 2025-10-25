---@diagnostic disable-next-line
STANDALONE.lua = {
	--- Generate a standalone Lua program from a given Paisley bytecode.
	--- which can be run without the need for the Paisley interpreter.
	--- @param bytecode table Paisley bytecode.
	--- @return string program_text The generated Lua program.
	generate = function(bytecode)
		require 'src.meta.lua'

		local init = [[
		VERSION = "]] .. (VERSION or 'unknown') .. [["
		V4 = os.time()
		V8 = 1000000000000
		V6 = arg
		V1 = "]] .. json.stringify(bytecode):
		gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'

		local prefix = --[[build-replace=src/util/output_pc.lua]] FS.open('src/util/output_pc.lua', true):read('*all') --[[/build-replace]]
		local text = --[[build-replace=src/runtime.lua]] FS.open('src/runtime.lua', true):read('*all') --[[/build-replace]]
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

	--- Compile a standalone Lua program into a binary executable.
	--- @param program_text string The Lua program text.
	--- @param output_file string The output file path.
	--- @param compiler string? The C compiler to use. If not provided, the default system compiler will be used.
	--- @return boolean success Whether the compilation was successful.
	compile = function(program_text, output_file, compiler)
		local version = _VERSION:match('[%d%.]+$')
		if version:sub(1, 2) ~= '5.' or tonumber(version:sub(3)) < 3 then
			version = '5.3' --Force version to 5.3 if not 5.3 or higher.
		end

		local pkg = package
		--[[no-install]]
		if package['initial'] then
			pkg = package['initial']
		end
		--[[/no-install]]

		local bytecode = { LUA.compile(program_text):byte(1, -1) }
		local pgm_buffer = '{' .. table.concat(bytecode, ',') .. '}'

		local c_code = [[
		#define LUA_IMPL
		#define LUA_COMPAT_MATHLIB
		#include <minilua.h>
		const char pgm[] = ]] .. pgm_buffer .. [[;
		int main(int argc, char **argv) {
			//Create state and load program.
			lua_State *L = luaL_newstate();
			if (L == NULL) return -1;
			luaL_openlibs(L);

			// Set up LuaRocks paths.
			luaL_dostring(L, "package.path = \"]] .. pkg.path .. [[\"");
			luaL_dostring(L, "package.cpath = \"]] .. pkg.cpath .. [[\"");

			int script = luaL_loadbufferx(L, pgm, ]] .. #pgm_buffer .. [[, "]] .. output_file .. [[", "b");

			//Set up arg table.
			lua_createtable(L, argc + 1, script);
			for (int i = 1; i < argc; i++) {
				lua_pushstring(L, argv[i]);
				lua_rawseti(L, -2, i);
			}
			lua_setglobal(L, "arg");

			//Run program.
			int status = lua_pcall(L, 0, 0, 0);
			if (status != 0) {
				fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
				lua_close(L);
				return -1;
			}
			lua_close(L);
			return 0;
		}
		]]

		local c_filename = os.tmpname() .. '.c'
		local c_file = io.open(c_filename, 'wb')
		if not c_file then
			error(
				'ERROR: Failed to open temporary C file for writing!. THIS IS MOST LIKELY A BUG IN THE COMPILER.')
		end

		c_file:write(c_code)
		c_file:close()

		if not compiler then
			compiler = STANDALONE.require_c_compiler()
		end

		local export_flag = '-Wl,-E'
		if FS.os.windows or compiler:find('mingw') then
			export_flag = '-Wl,--export-all-symbols'
		end

		local command = compiler .. ' -I' .. FS.libs_dir .. 'lua/' .. version ..
			' -o ' .. output_file .. ' ' .. c_filename .. ' -lm  ' .. export_flag

		io.stderr:write('[Compiling for Lua ' .. version .. ']\n')
		io.stderr:write(command .. '\n')

		local result = os.execute(command)

		os.remove(c_filename)

		return result == 0 or result == true
	end,
}
