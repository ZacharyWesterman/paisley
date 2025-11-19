local fs = require 'src.util.filesystem'

---@diagnostic disable-next-line
STANDALONE.cpp = {
	--- Generate a standalone C++ program from a given Paisley bytecode.
	--- which can be run without the need for the Paisley interpreter.
	--- @param bytecode table Paisley bytecode.
	--- @return string program_text The generated C++ program.
	generate = function(bytecode)
		local text = "#include \"PAISLEY_BYTECODE.hpp\"\n\n"
		text = text .. "const std::vector<Instruction> INSTRUCTIONS = {\n"
		for i = 1, #bytecode - 1 do
			local instr = bytecode[i]
			text = text .. '\t{ ' ..
				(tonumber(instr[1]) or 0) .. ', ' ..
				(tonumber(instr[2]) or 0) .. ', ' ..
				(tonumber(instr[3]) or 0) .. ', ' ..
				(tonumber(instr[4]) or 0) .. ' },\n'
		end

		local function escape_str(str)
			return '"' .. str:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"'):gsub('\0', '\\0') .. '"s'
		end

		local function value_to_cpp(value)
			local tp = std.type(value)
			if tp == 'string' then
				return escape_str(value)
			elseif tp == 'number' then
				return tostring(value)
			elseif tp == 'boolean' then
				return value and 'true' or 'false'
			elseif tp == 'array' then
				local text = 'std::vector<Value>({'
				for i = 1, #value do
					text = text .. value_to_cpp(value[i]) .. ','
				end
				text = text .. '})'
				return text
			elseif tp == 'object' then
				local text = 'std::map<std::string, Value>({'
				for k, v in pairs(value) do
					text = text .. '{' .. escape_str(std.str(k)) .. ', ' .. value_to_cpp(v) .. '},'
				end
				text = text .. '})'
				return text
			end

			return 'Value()' --nil
		end

		text = text .. '};\n\nconst std::vector<Value> CONSTANTS = {\n\tNull(),\n'
		for i = 1, #bytecode[#bytecode] do
			local value = bytecode[#bytecode][i]
			text = text .. '\t' .. value_to_cpp(value) .. ',\n'
		end

		text = text .. '};\n\nconst bool SANDBOXED = ' .. (_G['SANDBOX'] and 'true' or 'false') .. ';\n'
		---@diagnostic disable-next-line
		text = text .. 'const std::string VERSION = ' .. escape_str(VERSION or 'unknown') .. ';\n'

		return text;
	end,

	--- Compile a standalone C++ program into a binary executable.
	--- @param program_text string The C++ program text.
	--- @param output_file string The output file path.
	--- @return boolean success Whether the compilation was successful.
	compile = function(program_text, output_file)
		local cc = STANDALONE.require_cpp_compiler()
		local make = STANDALONE.require_make()

		local temp_file = fs.open_lib('cpp/PAISLEY_BYTECODE.cpp', 'w')

		if not temp_file then
			error('Error: Could not open PAISLEY_BYTECODE.hpp for writing.\nAre you sure the directory is writable?')
			return false
		end

		temp_file:write(program_text)
		temp_file:close()

		local success = os.execute(make .. ' -C ' .. fs.libs_dir .. 'cpp -j32')

		if success then
			os.execute('mv ' .. fs.libs_dir .. 'cpp/standalone_binary ' .. output_file)
			return true
		end

		return false
	end,

	--- Precompile the C++ runtime for the standalone program.
	--- This can be used to speed up the compilation process later on.
	--- @return boolean success Whether the precompilation was successful.
	precompile = function()
		local cc = STANDALONE.require_cpp_compiler()
		local make = STANDALONE.require_make()

		local success = os.execute(make .. ' objects -C ' .. fs.libs_dir .. 'cpp -j32')

		if not success then
			error('Error: Could not precompile the C++ runtime.\nAre you sure the directory is writable?')
			return false
		end

		return true
	end,

	--- Remove precompiled C++ object files.
	clean = function()
		local make = STANDALONE.require_make()

		local success = os.execute(make .. ' clean -C ' .. fs.libs_dir .. 'cpp')

		if not success then
			error('Error: Could not clean the C++ runtime.\nAre you sure the directory is writable?')
			return false
		end

		return true
	end
}
