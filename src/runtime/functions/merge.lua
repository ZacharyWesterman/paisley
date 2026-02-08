return function(vm)
	local v = vm.pop()
	if type(v[1]) ~= 'table' then v[1] = { v[1] } end
	if type(v[2]) ~= 'table' then v[2] = { v[2] } end

	for i = 1, #v[2] do
		table.insert(v[1], v[2][i])
	end
	vm.push(v[1])
end
