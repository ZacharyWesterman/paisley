return function(vm)
	--Environment variables are always null in the plasma build.

	--[[minify-delete]]
	if true then
		vm.push(os.getenv(std.str(vm.pop()[1])))
	else
		--[[/minify-delete]]
		vm.pop()
		vm.push(nil)
		--[[minify-delete]]
	end
	--[[/minify-delete]]
end
