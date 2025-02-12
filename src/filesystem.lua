local function soft_require(module)
	local success, result = pcall(require, module)
	if success then return result end
end

FS = {
	os = {
		windows = package.config:sub(1, 1) == '\\',
		linux = package.config:sub(1, 1) == '/',
	},

	rocks = {
		lfs = soft_require('lfs'),
		zlib = soft_require('zlib'),
	},

	script_real_path = function()
		local path = arg[0]

		if FS.os.windows then
			local ffi_installed, ffi = pcall(require, 'ffi')

			if not ffi_installed then return '' end

			ffi.cdef [[
				typedef unsigned long DWORD;
				typedef char CHAR;
				typedef DWORD ( __stdcall *GetFullPathNameA_t )(const CHAR*, DWORD, CHAR*, CHAR**);
			]]
			local kernel32 = ffi.load("kernel32")
			local MAX_PATH = 260
			local buf = ffi.new("char[?]", MAX_PATH)
			local getFullPathName = ffi.cast("GetFullPathNameA_t", kernel32.GetFullPathNameA)
			local length = getFullPathName(path, MAX_PATH, buf, nil)
			if length == 0 then
				return '' -- Failed to get path
			else
				return ffi.string(buf, length)
			end
		else
			-- If on Linux, resolve symbolic links
			local resolvedPath = io.popen("readlink -f " .. path):read("*a")
			if resolvedPath then
				return resolvedPath:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
			else
				return ''                          -- Failed to get path
			end
		end
	end,

	exec_dir = "-UNDEF-",
	working_dir = "",

	open = function(filename, exec_dir)
		if exec_dir then
			return io.open(FS.exec_dir .. filename, "r")
		else
			return io.open(FS.working_dir .. filename, "r")
		end
	end,
}

--Setup filesystem constants
FS.exec_dir = FS.script_real_path():match("(.*[/\\])") or ""
FS.working_dir = FS.exec_dir
if FS.rocks.lfs then FS.working_dir = FS.rocks.lfs.currentdir() end
