function generate_bytecode(root, file)
	local instructions = {}
	local codegen_rules

	--List of possible bytecode instructions
	local bc = {
		read = 0,
		write = 1,
		call = 2,
		label = 3,
		jump = 4,
		set = 5,
		run_command = 6,
		push = 7,
		pop = 8,
	}

	local current_line = 0

	local function emit(instruction_id, param1)
		table.insert(instructions, {instruction_id, param1, param2, current_line})

		--TEMP: print code as it's generated
		local instr_text
		local i, k
		for k, i in pairs(bc) do
			if i == instruction_id then
				instr_text = k
				break
			end
		end

		if not instr_text then
			parse_error(0, 0, 'COMPILER ERROR: Unknown bytecode instruction with id '..insruction_id..'!', file)
		end

		print(current_line..': '..instr_text..' '..std.debug_str(param1))

		return #instructions
	end

	local function enter(token)
		if not codegen_rules[token.id] then
			parse_error(token.line, token.col, 'COMPILER ERROR: Unable to generate bytecode for object "'..token_text(token.id)..'"!', file)
		end

		current_line = token.line
		codegen_rules[token.id](token, file)
	end

	local function is_const(token) return token.value ~= nil or token.id == tok.lit_null end

	--[[
		CODE GENERATION RULES
	]]
	codegen_rules = {
		--CODEGEN FOR COMMANDS
		[tok.command] = function(token, file)
			local i
			for i = 1, #token.children do
				local ch = token.children[i]
				if is_const(ch) then
					emit(bc.push, ch.value)
				else
					enter(ch)
				end
			end

			emit(bc.run_command)
		end,

		--CODEGEN FOR VARIABLE ASSIGNMENT
		[tok.let_stmt] = function(token, file)
			local var_name = token.children[1]
			local var_value = token.children[2]

			if is_const(var_value) then
				emit(bc.push, var_value.value)
			else
				enter(var_value)
			end
			emit(bc.set, var_name.text)
		end,

		--Shortcut for binary operations, since they're all basically the same from a code gen perspective
		binary_op = function(token, operation_name)
			codegen_rules.recur_push(token.children[1])
			codegen_rules.recur_push(token.children[2])
			emit(bc.call, operation_name)
		end,

		recur_push = function(token)
			if is_const(token) then emit(bc.push, token.value) else enter(token) end
		end,

		--CODEGEN FOR ARRAY CONCATENATION
		[tok.array_concat] = function(token, file)
			emit(bc.push, {})

			local i
			for i = 1, #token.children do
				codegen_rules.recur_push(token.children[i])
				emit(bc.call, 'append')
			end
		end,

		--CODEGEN FOR VARIABLES
		[tok.variable] = function(token, file)
			emit(bc.read, token.text)
		end,
	}

	enter(root)
	return instructions
end
