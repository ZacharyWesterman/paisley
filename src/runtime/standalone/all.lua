local function find_compiler(compilers)
	for _, compiler in ipairs(compilers) do
		if os.execute(compiler .. ' --version > /dev/null 2>&1') then
			return compiler
		end
	end
end

STANDALONE = {
	--- Get the C compiler to use for compiling the standalone program.
	--- If no C compiler is found, an error is thrown.
	--- @return string cc The C compiler to use.
	require_c_compiler = function()
		local cc = find_compiler({ 'cc', 'gcc', 'clang', 'cl' })

		if not cc then
			error('ERROR: No C compiler found. Please install a C compiler to compile the standalone program.')
		end

		return cc
	end,

	--- Get the C++ compiler to use for compiling the standalone program.
	--- If no C++ compiler is found, an error is thrown.
	--- @return string cc The C++ compiler to use.
	require_cpp_compiler = function()
		local cc = find_compiler({ 'c++', 'g++', 'clang++', 'cl' })

		if not cc then
			error('ERROR: No C++ compiler found. Please install a C++ compiler to compile the standalone program.')
		end

		return cc
	end,
}

require 'src.runtime.standalone.lua'
