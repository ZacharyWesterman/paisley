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
		get = 6,
		run_command = 7,
		push = 8,
		pop = 9,
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

	--Generate unique label ids (ones that can't clash with user-defined labels)
	local label_counter = 0
	local function label_id()
		label_counter = label_counter + 1
		return '?'..label_counter
	end

	local loop_term_labels = {}
	local loop_begn_labels = {}

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
				table.insert(p, std.str(token.children[i].value))
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

		--STRING CONCATENATION
		[tok.string_open] = function(token, file)
			local i
			for i = 1, #token.children do
				codegen_rules.recur_push(token.children[i])
			end
			emit(bc.call, 'concat', #token.children)
		end,

		--MULTIPLICATION OPERATIONS
		[tok.multiply] = function(token, file)
			if token.text == '//' then
				--No such thing as integer division really, it's just division, rounded down.
				codegen_rules.binary_op(token, 'div')
				emit(bc.call, 'floor')
			else
				local op = {
					['*'] = 'mult',
					['/'] = 'div',
					['%'] = 'remd',
				}
				codegen_rules.binary_op(token, op[token.text])
			end
		end,

		--ADDITION OPERATIONS
		[tok.add] = function(token, file)
			local op = {
				['+'] = 'add',
				['-'] = 'sub',
			}
			codegen_rules.binary_op(token, op[token.text])
		end,

		--NEGATE
		[tok.negate] = function(token, file)
			--No real negate operation, it's just zero minus the value
			emit(bc.push, 0)
			codegen_rules.recur_push(token.children[1])
			emit(bc.call, 'sub')
		end,

		--FOR LOOPS
		[tok.for_stmt] = function(token, file)
			local loop_beg_label = label_id()
			local loop_end_label = label_id()

			--Loop setup
			emit(bc.push, nil)
			codegen_rules.recur_push(token.children[2])

			if token.children[3] == nil then
				emit(bc.pop)
				return
			end

			emit(bc.call, 'explode')
			emit(bc.label, loop_beg_label)
			table.insert(loop_term_labels, loop_end_label)
			table.insert(loop_begn_labels, loop_beg_label)

			--Run loop
			emit(bc.call, 'jumpifnil', loop_end_label)
			emit(bc.set, token.children[1].text)

			enter(token.children[3])

			--End of loop
			emit(bc.call, 'jump', loop_beg_label)
			emit(bc.label, loop_end_label)
			table.remove(loop_term_labels)
			table.remove(loop_begn_labels)
		end,

		[tok.break_stmt] = function(token, file)
			if #loop_term_labels == 0 then
				parse_error(token.line, token.col, 'Break statements are meaningless outside of a loop', file)
			end

			if #loop_term_labels < token.children[1].value then
				local word = 'loop'
				if #loop_term_labels ~= 1 then word = 'loops' end
				parse_error(token.line, token.col, 'Unable to break out of '..token.children[1].value..' loops, only '..#loop_term_labels..' '..word..' found')
			end

			emit(bc.call, 'jump', loop_term_labels[#loop_term_labels - token.children[1].value + 1])
		end,
	}

	enter(root)
	return instructions
end
