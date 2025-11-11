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

	disable_rocks = function()
		for key, _ in pairs(FS.rocks) do
			FS.rocks[key] = nil
		end
	end,

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

	--- Check if a file or directory exists at the given path.
	--- @param path string
	--- @return boolean result true if the file or directory exists, false otherwise
	file_exists = function(path)
		local file = io.open(path, "r")
		if file then
			file:close()
			return true
		else
			return false
		end
	end,

	--- Get the size of a file at the given path.
	--- @param path string
	--- @return number size The size of the file in bytes, or 0 if the file does not exist or is not readable.
	file_size = function(path)
		local file = io.open(path, "r")
		if file then
			local size, error = file:seek("end")
			file:close()
			if error then
				return 0
			else
				return size
			end
		else
			return 0
		end
	end,

	--- Read the entire content of a file at the given path.
	--- @param path string
	--- @return string|nil content The content of the file as a string, or nil if the file does not exist or is not readable.
	file_read = function(path)
		local file = io.open(path, "r")
		if file then
			local content = file:read("*a")
			file:close()
			return content
		else
			return nil
		end
	end,

	--- Write content to a file at the given path, overwriting any existing content.
	--- @param path string
	--- @param content string
	--- @param append boolean If true, append to the file instead of overwriting it.
	--- @return boolean success true if the write operation was successful, false otherwise.
	file_write = function(path, content, append)
		local mode = append and "a" or "w"
		local file = io.open(path, mode)
		if file then
			file:write(content)
			file:close()
			return true
		else
			return false
		end
	end,

	--- Delete a file at the given path.
	--- @param path string The path of the file to delete.
	--- @return boolean success true if the file was successfully deleted, false otherwise.
	file_delete = function(path)
		if os.remove(path) then
			return true
		else
			return false
		end
	end,

	--- Create a directory at the given path.
	--- @param path string The path of the directory to create.
	--- @param recursive boolean If true, create parent directories as needed.
	--- @return boolean success true if the directory was successfully created, false otherwise.
	dir_create = function(path, recursive)
		local command = recursive and 'mkdir -p "%s"' or 'mkdir "%s"'
		local result = os.execute(string.format(command, path))
		return result == 0
	end,

	--- Delete a directory at the given path.
	--- @param path string The path of the directory to delete.
	--- @param recursive boolean If true, delete the directory and its contents recursively.
	--- @return boolean success true if the directory was successfully deleted, false otherwise.
	dir_delete = function(path, recursive)
		local command
		if FS.os.windows then
			command = recursive and 'rmdir /s /q "%s"' or 'rmdir "%s"'
		else
			command = recursive and 'rm -rf "%s"' or 'rmdir "%s"'
		end
		local result = os.execute(string.format(command, path))
		return result == 0
	end,

	--- List the contents of a directory at the given path.
	--- @param path string The path of the directory to list.
	--- @return table|nil contents A table of filenames in the directory, or nil if the directory does not exist or is not readable.
	dir_list = function(path)
		local contents = std.array()
		local lfs = FS.rocks.lfs
		if not lfs or not FS.file_exists(path) then return contents end

		for filename in lfs.dir(path) do
			if filename ~= "." and filename ~= ".." then
				table.insert(contents, filename)
			end
		end
		return contents
	end,

	--- Get the type of a file at the given path.
	--- @param path string The path of the file to check.
	--- @return string|nil filetype The type of the file: "file", "directory", "other", or nil if the path does not exist.
	file_type = function(path)
		local lfs = FS.rocks.lfs
		if not lfs then return nil end

		local attr = lfs.attributes(path)
		if not attr then return "other" end

		if attr.mode == "file" then
			return "file"
		elseif attr.mode == "directory" then
			return "directory"
		else
			return "other"
		end
	end,

	--- Get file information at the given path.
	--- @param path string The path of the file to check.
	--- @return table|nil info A table containing file attributes, or nil if the path does not exist.
	file_stat = function(path)
		local lfs = FS.rocks.lfs
		if not lfs then return nil end
		local attr = lfs.attributes(path)
		std.set_table_type(attr, false)
		return attr
	end,

	--- Copy a file from source to destination.
	--- @param src string The path of the source file.
	--- @param dest string The path of the destination file.
	--- @param overwrite boolean If true, overwrite the destination file if it exists.
	--- @return boolean success true if the file was successfully copied, false otherwise.
	file_copy = function(src, dest, overwrite)
		if not FS.file_exists(src) then return false end
		if FS.file_exists(dest) and not overwrite then return false end

		local input = io.open(src, "rb")
		if not input then return false end
		local output = io.open(dest, "wb")
		if not output then
			input:close()
			return false
		end

		local content = input:read("*a")
		output:write(content)
		input:close()
		output:close()
		return true
	end,

	--- Move (rename) a file from source to destination.
	--- @param src string The path of the source file.
	--- @param dest string The path of the destination file.
	--- @param overwrite boolean If true, overwrite the destination file if it exists.
	--- @return boolean success true if the file was successfully moved, false otherwise.
	file_move = function(src, dest, overwrite)
		if not overwrite and FS.file_exists(dest) then return false end

		local success = os.rename(src, dest)
		return success
	end
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
