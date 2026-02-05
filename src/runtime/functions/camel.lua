return function(vm)
	local v = std.str(vm.pop())
	vm.push(v:gsub('(%l)(%w*)', function(x, y) return x:upper() .. y end))
end
