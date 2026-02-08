local fs = require 'src.util.filesystem'

return function(vm) vm.push(fs.file_delete(std.str(vm.pop()[1]))) end
