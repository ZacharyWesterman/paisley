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

	local function emit(instruction_id, param1, param2)
		table.insert(instructions, {instruction_id, param1, param2, current_line})

		local instr_text
		local i, k
		for k, i in pairs(bc) do
			if i == instruction_id then
				instr_text = k
				break
			end
		end

		if not instr_text then
			parse_error(0, 0, 'COMPILER BUG: Unknown bytecode instruction with id '..instruction_id..'!', file)
		end

		--TEMP: print code as it's generated
		if param1 == nil and instruction_id ~= bc.run_command then param1 = 'null' else param1 = std.debug_str(param1) end
		if param2 then
			print(current_line..': '..instr_text..' '..param1..' '..std.debug_str(param2))
		else
			print(current_line..': '..instr_text..' '..param1)
		end

		return #instructions
	end

	local function enter(token)
		if not codegen_rules[token.id] then
			parse_error(token.line, token.col, 'COMPILER BUG: Unable to generate bytecode for token of type "'..token_text(token.id)..'"!', file)
		end

		current_line = token.line
		codegen_rules[token.id](token, file)
	end

	local function is_const(token) return token.value ~= nil or token.id == tok.lit_null end

	--[[
		CODE GENERATION RULES
	]]
	codegen_rules = {
		--Shortcut for binary operations, since they're all basically the same from a code gen perspective
		binary_op = function(token, operation_name)
			codegen_rules.recur_push(token.children[1])
			codegen_rules.recur_push(token.children[2])
			emit(bc.call, operation_name)
		end,

		recur_push = function(token)
			if is_const(token) then emit(bc.push, token.value) else enter(token) end
		end,

		--CODEGEN FOR PROGRAM (Just a list of commands/statements)
		[tok.program] = function(token, file)
			local i
			for i = 1, #token.children do
				enter(token.children[i])
			end
		end,

		--CODEGEN FOR COMMANDS
		[tok.command] = function(token, file)
			local all_const, p, i = true, {}
			for i = 1, #token.children do
				if not is_const(token.children[i]) then
					all_const = false
					break
				end
				table.insert(p, token.children[i].value)
			end

			if all_const then
				emit(bc.push, p)
			else
				for i = 1, #token.children do
					codegen_rules.recur_push(token.children[i])
				end
				emit(bc.call, 'make_array', #token.children)
			end
			emit(bc.run_command)
		end,

		--CODEGEN FOR VARIABLE ASSIGNMENT
		[tok.let_stmt] = function(token, file)
			codegen_rules.recur_push(token.children[2])
			emit(bc.set, token.children[1].text)
		end,

		--CODEGEN FOR ARRAY CONCATENATION
		[tok.array_concat] = function(token, file)
			emit(bc.push, {})

			local i
			for i = 1, #token.children do
				codegen_rules.recur_push(token.children[i])
			end
			emit(bc.call, 'make_array', #token.children)
		end,

		--CODEGEN FOR VARIABLES
		[tok.variable] = function(token, file)
			emit(bc.read, token.text)
		end,

		--DELETE STATEMENT
		[tok.delete_stmt] = function(token, file)
			local i
			for i = 1, #token.children do
				emit(bc.push, nil)
				emit(bc.set, token.children[i].text)
			end
		end,

		[tok.string_open] = function(token, file)
			local i
			for i = 1, #token.children do
				codegen_rules.recur_push(token.children[i])
			end
			emit(bc.call, 'concat', #token.children)
		end,
	}

	enter(root)
	return instructions
end
