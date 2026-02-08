local fs = require 'src.util.filesystem'

return function(vm)
	local pattern = std.str(vm.pop()[1])

	local lfs = fs.rocks.lfs
	if not lfs then
		error('Error in file_glob(): Lua lfs module not installed!')
		return
	end

	vm.push(fs.glob_files(pattern))
end
