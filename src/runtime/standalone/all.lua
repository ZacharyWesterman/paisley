local function find_compiler(compilers)
	for _, compiler in ipairs(compilers) do
		if os.execute(compiler .. ' --version > /dev/null 2>&1') then
			return compiler
		end
	end
end

local fs = require 'src.util.filesystem'

STANDALONE = {
	--- Get the C compiler to use for compiling the standalone program.
	--- If no C compiler is found, an error is thrown.
	--- @return string cc The C compiler to use.
	require_c_compiler = function()
		local cc = find_compiler({ 'cc', 'gcc', 'clang', 'mingw32-gcc' })

		if not cc then
			error('ERROR: No C compiler found. Please install a C compiler to compile the standalone program.')
		end

		return cc
	end,

	--- Get the C++ compiler to use for compiling the standalone program.
	--- If no C++ compiler is found, an error is thrown.
	--- @return string cc The C++ compiler to use.
	require_cpp_compiler = function()
		local cc = find_compiler({ 'c++', 'g++', 'clang++', 'mingw32-g++' })

		if not cc then
			error('ERROR: No C++ compiler found. Please install a C++ compiler to compile the standalone program.')
		end

		return cc
	end,

	--- Get the installed version of Make.
	--- If no Make is found, an error is thrown.
	--- @return string make The Make program to use.
	require_make = function()
		local make = find_compiler({ 'make' })

		if not make then
			error('ERROR: No Make program found. Please install Make to compile the standalone program.')
		end

		return make
	end,

	compress_executable = function(executable)
		if fs.os.windows then
			error('Error: Compression of standalone binaries is not supported on Windows (requires gzexe).')
		end

		--Move the file to a temporary location so that we can compress it.
		--(gzexe sometimes fails on file names like `test`)
		local tempfile = os.tmpname()
		os.execute('mv ' .. executable .. ' ' .. tempfile)
		if os.execute('gzexe ' .. tempfile) then
			os.execute('rm -f ' .. tempfile .. '~')
			os.execute('mv ' .. tempfile .. ' ' .. executable)
		else
			os.execute('rm -f ' .. tempfile .. ' ' .. executable)
		end
	end,
}

require 'src.runtime.standalone.lua'
require 'src.runtime.standalone.cpp'
