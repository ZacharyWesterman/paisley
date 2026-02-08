local fs = require 'src.util.filesystem'

return function(vm)
	local v = vm.pop()
	vm.push(fs.file_write(std.str(v[1]), std.str(v[2]), true))
end
