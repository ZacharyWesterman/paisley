return {
	mathfunc = function(funcname)
		return function(vm, line)
			local v, p = vm.pop(), {}
			for i = 1, #v do
				table.insert(p, std.num(v[i]))
			end

			---@diagnostic disable-next-line
			local u = table.unpack or unpack

			--If null was passed to the function, in a way that could not be determined at compile time, coerce it to be zero.
			if #p == 0 then
				print('WARNING: line ' .. line .. ': Null passed to math function, coerced to 0')
				p = { 0 }
			end

			local fn = math[funcname]
			if not fn then
				vm.runtime_error(line, 'RUNTIME BUG: Math function "' .. funcname .. '" does not exist')
			end

			local val1, val2 = fn(u(p))
			if val2 then
				vm.push({ val1, val2 })
			else
				vm.push(val1)
			end
		end
	end,

	---Format two parameters and perform a binary operation on them.
	---@param format_func fun(param: any): any The function to format the parameters with.
	---@param operate_func fun(param1: any, param2: any): any The operation to perform on the two parameters.
	---@return fun(vm: table, line: number): nil runtime_function The function to execute the operation.
	operator = function(format_func, operate_func)
		return function(vm, line)
			local v2, v1 = vm.pop(), vm.pop()

			if type(v1) == 'table' or type(v2) == 'table' then
				if type(v1) ~= 'table' then v1 = { v1 } end
				if type(v2) ~= 'table' then v2 = { v2 } end

				local result = {}
				for i = 1, math.min(#v1, #v2) do
					table.insert(result, operate_func(format_func(v1[i]), format_func(v2[i])))
				end
				vm.push(result)
			else
				vm.push(operate_func(format_func(v1), format_func(v2)))
			end
		end
	end,


	---Perform operations on two sets.
	---@param func fun(a: table, b: table): table The function to perform on the two sets.
	---@return fun(vm: table, line: number): nil runtime_function The function to execute the operation.
	set_operator = function(func)
		return function(vm, line)
			local v = vm.pop()
			local a, b = v[1], v[2]
			if type(a) ~= 'table' then a = { a } end
			if type(b) ~= 'table' then b = { b } end
			vm.push(func(a, b))
		end
	end,
}
