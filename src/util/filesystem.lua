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
		curses = soft_require('curses'),
		socket = soft_require('socket'),
	},

	script_real_path = function()
		local path = arg[0]

		if FS.os.windows then
			local ffi_installed, ffi = pcall(require, 'ffi')

			if not ffi_installed then return '' end

			ffi.cdef [[typedef unsigned long DWORD;typedef DWORD(__stdcall *GetFullPathNameA_t)(const char*, DWORD, char*, char**);]]
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
	libs_dir = "-UNDEF-",

	open = function(filename, exec_dir)
		if exec_dir then
			return io.open(FS.exec_dir .. filename, "r")
		else
			return io.open(FS.working_dir .. filename, "r")
		end
	end,

	open_lib = function(filename, mode)
		return io.open(FS.libs_dir .. filename, mode)
	end,

	is_paisley_bytecode = function(text)
		require 'src.shared.json'

		--Trim whitespace
		text = text:gsub('^%s*(.-)%s*$', '%1')

		if text:sub(1, 2) ~= '[[' or text:sub(#text - 1, #text) ~= ']]' then return false end
		return json.verify(text)
	end,

	is_zlib_compressed = function(text)
		if not FS.rocks.zlib then return false end

		local header = text:sub(1, 2)
		if #header < 2 then return false end

		-- Convert the two bytes to integer values
		local byte1, byte2 = header:byte(1, 2)

		-- Check the zlib header
		-- The first byte (CMF - Compression Method and Flags)
		-- The second byte (FLG - Additional Flags)
		return (byte1 == 0x78) and (byte2 == 0x01 or byte2 == 0x9C or byte2 == 0xDA)
	end,

	stdlib = function(require_path)
		if FS.exec_dir == nil then return nil, require_path end

		local fname = 'stdlib/' .. require_path:gsub('%.', '/') .. '.pai'
		local fp = FS.open(fname, true)
		if not fp then
			fname = fname .. 'sley'
			fp = FS.open(fname, true)
		end

		return fp, FS.exec_dir .. fname
	end,

	cd = function(path)
		if FS.rocks.lfs then
			FS.rocks.lfs.chdir(path)
			FS.working_dir = FS.rocks.lfs.currentdir() .. '/'
		end
	end,

	pwd = function(path)
		if FS.rocks.lfs then
			return FS.rocks.lfs.currentdir()
		end
	end,

	glob_files = function(pattern)
		local function split_path(path)
			local dir, pattern = path:match("(.-)/([^/]*)$")
			if not dir then
				return "./", path -- Handle cases like "*.txt"
			end
			return dir or "./", pattern or "*"
		end

		local function match_pattern(filename, pattern)
			local lua_pattern = "^" .. pattern:gsub("%.", "%%.")
				:gsub("%*", ".*")
				:gsub("%?", ".") .. "$"
			return filename:match(lua_pattern) ~= nil
		end

		local function glob(pattern)
			local dir, file_pattern = split_path(pattern)
			local matches = {}

			for file in FS.rocks.lfs.dir(dir) do
				if file ~= "." and file ~= ".." and match_pattern(file, file_pattern) then
					local path = (dir .. "/" .. file):gsub("//", "/")
					if pattern:sub(1, 2) ~= './' and path:sub(1, 2) == './' then
						path = path:sub(3)
					end
					table.insert(matches, path)
				end
			end

			return matches
		end

		if not FS.rocks.lfs then return {} end
		return glob(pattern)
	end,
}

--Setup filesystem constants

--[[no-install]]
FS.exec_dir = FS.script_real_path():match("(.*[/\\])") or ""
FS.libs_dir = FS.exec_dir .. 'src/libs/'
if false then
	--[[/no-install]]
	if FS.os.windows then
		FS.exec_dir = os.getenv('APPDATA') .. '\\paisley\\'
		FS.libs_dir = FS.exec_dir .. 'libs\\'
	else
		FS.exec_dir = '/usr/local/share/paisley/'
		FS.libs_dir = '/usr/local/lib/paisley/'
	end
	--[[no-install]]
end
--[[/no-install]]

FS.working_dir = FS.exec_dir
if FS.rocks.lfs then FS.working_dir = FS.rocks.lfs.currentdir() .. '/' end
