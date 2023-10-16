function generate_bytecode(root, file)
	local instructions = {}
	local codegen_rules

	--List of possible bytecode instructions
	local bc = {
		call = 0,
		label = 1,
		set = 2,
		get = 3,
		push = 4,
		pop = 5,
		run_command = 6,
		push_cmd_result = 7,
		push_index = 8,
		pop_goto_index = 9,
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
		if param1 == nil and instruction_id ~= bc.run_command and instruction_id ~= bc.push_cmd_result and instruction_id ~= bc.pop and instruction_id ~= bc.push_index and instruction_id ~= bc.pop_goto_index then param1 = 'null' else param1 = std.debug_str(param1) end
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

	--Generate unique label ids (ones that can't clash with subroutine names)
	local label_counter = 0
	local function label_id()
		label_counter = label_counter + 1
		return '?'..label_counter
	end

	local loop_term_labels = {}
	local loop_begn_labels = {}

	--Create a termination label which will be appended to the end
	local EOF_LABEL = label_id()

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
				emit(bc.call, 'implode', #token.children)
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
			local i
			local has_slices = false
			for i = 1, #token.children do
				local chid = token.children[i].id
				if chid == tok.array_slice or chid == tok.lit_array then has_slices = true end
				codegen_rules.recur_push(token.children[i])
			end

			if has_slices then
				emit(bc.call, 'superimplode', #token.children)
			else
				emit(bc.call, 'implode', #token.children)
			end
		end,

		--ARRAY SLICE
		[tok.array_slice] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			codegen_rules.recur_push(token.children[2])
			emit(bc.call, 'arrayslice')
		end,

		--STRING CONCAT
		[tok.concat] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			codegen_rules.recur_push(token.children[2])
			emit(bc.call, 'concat')
		end,

		--CODEGEN FOR VARIABLES
		[tok.variable] = function(token, file)
			emit(bc.get, token.text)
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
					['*'] = 'mul',
					['/'] = 'div',
					['%'] = 'rem',
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

		--LENGTH OPERATOR
		[tok.length] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			emit(bc.call, 'length')
		end,

		--INDEXING
		[tok.index] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			codegen_rules.recur_push(token.children[2])
			emit(bc.call, 'index')
		end,

		--BOOLEAN OPERATIONS
		[tok.boolean] = function(token, file)
			local op = {
				['and'] = 'booland',
				['or'] = 'boolor',
				['xor'] = 'boolxor',
				['not'] = 'boolnot',
				['in'] = 'inarray',
				['like'] = 'strlike',
				['exists'] = 'varexists',
			}

			if #token.children > 1 then
				codegen_rules.binary_op(token, op[token.text])
			else
				codegen_rules.recur_push(token.children[1])
				emit(bc.call, op[token.text])
			end
		end,

		--COMPARISON OPERATIONS (also boolean technically)
		[tok.comparison] = function(token, file)
			local op = {
				['=='] = 'equal',
				['!='] = 'notequal',
				['>'] = 'greater',
				['>='] = 'greaterequal',
				['<'] = 'less',
				['<='] = 'lessequal',
			}
			codegen_rules.binary_op(token, op[token.text])
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

		--WHILE LOOPS
		[tok.while_stmt] = function(token, file)
			local loop_beg_label = label_id()
			local loop_end_label = label_id()

			local const = is_const(token.children[1])
			local val = std.bool(token.children[1].value)

			--If the loop will never get executed, don't generate it.
			if const and not val then return end

			--Loop setup
			emit(bc.label, loop_beg_label)
			table.insert(loop_term_labels, loop_end_label)
			table.insert(loop_begn_labels, loop_beg_label)
			codegen_rules.recur_push(token.children[1])

			--Run loop
			emit(bc.call, 'jumpiffalse', loop_end_label)
			emit(bc.pop)

			if #token.children >= 2 then
				enter(token.children[2])
			end

			--End of loop
			emit(bc.call, 'jump', loop_beg_label)
			emit(bc.label, loop_end_label)
			emit(bc.pop)
		end,

		--BREAK STATEMENT
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

		--CONTINUE STATEMENT
		[tok.continue_stmt] = function(token, file)
			if #loop_begn_labels == 0 then
				parse_error(token.line, token.col, 'Continue statements are meaningless outside of a loop', file)
			end

			if #loop_begn_labels < token.children[1].value then
				local word = 'loop'
				if #loop_begn_labels ~= 1 then word = 'loops' end
				parse_error(token.line, token.col, 'Unable to skip iteration of '..token.children[1].value..' loops, only '..#loop_begn_labels..' '..word..' found')
			end

			emit(bc.call, 'jump', loop_begn_labels[#loop_begn_labels - token.children[1].value + 1])
		end,

		--INLINE COMMAND EVALUATION
		[tok.inline_command] = function(token, file)
			enter(token.children[1])
			emit(bc.push_cmd_result)
		end,

		--IF STATEMENT
		[tok.if_stmt] = function(token, file)
			local const = is_const(token.children[1])
			local val = std.bool(token.children[1].value)
			local endif_label

			--Only generate the branch if it's possible for it to execute.
			if not const or val then
				local else_label

				--Don't generate a label if the "if" part will always execute
				if not const then
					else_label = label_id()
					endif_label = label_id()
					enter(token.children[1])
					emit(bc.call, 'jumpiffalse', else_label)
					emit(bc.pop)
				end

				--IF statement body
				enter(token.children[2])

				if not const then
					emit(bc.call, 'jump', endif_label) --Skip the "else" section if the "if" section executed
					emit(bc.label, else_label)
					emit(bc.pop)
				end
			end

			--Generate the "else" part of the if statement
			--Only if it's possible for the "if" part to not execute.
			if #token.children > 2 and token.children[3].id ~= tok.kwd_end and not (const and val) then
				local else_block = token.children[3]
				if else_block.id == tok.else_stmt then
					enter(else_block.children[1])
				else
					enter(else_block)
				end

				if not const then emit(bc.label, endif_label) end
			end
		end,

		--ELIF STATEMENT (Functionally identical to the IF statement)
		[tok.elif_stmt] = function(token, file) codegen_rules[tok.if_stmt](token, file) end,

		--GOSUB STATEMENT
		[tok.gosub_stmt] = function(token, file)
			if not token.ignore then
				emit(bc.push_index)
				emit(bc.call, 'jump', token.children[1].text)
			end
		end,

		--SUBROUTINES. These are basically just a label and a return statement
		[tok.subroutine] = function(token, file)
			--Don't generate code for the subroutine if it contains nothing.
			--If it contains nothing then references to it have already been removed.
			if not token.ignore then
				local skipsub = label_id()
				emit(bc.call, 'jump', skipsub)
				emit(bc.label, token.text:sub(1, #token.text - 1))
				enter(token.children[1])
				emit(bc.pop_goto_index)
				emit(bc.label, skipsub)
			end
		end,

		--RETURN STATEMENT
		[tok.kwd_return] = function(token, file)
			emit(bc.pop_goto_index)
		end,

		--BUILT-IN FUNCTION CALLS
		[tok.func_call] = function(token, file)
			local i
			local has_slices = false
			for i = 1, #token.children do
				local chid = token.children[i].id
				if chid == tok.array_slice or chid == tok.lit_array then has_slices = true end
				codegen_rules.recur_push(token.children[i])
			end

			if has_slices then
				emit(bc.call, 'superimplode', #token.children)
			else
				emit(bc.call, 'implode', #token.children)
			end
			emit(bc.call, token.text)
		end,

		--STOP statement
		[tok.kwd_stop] = function(token, file)
			emit(bc.call, 'jump', EOF_LABEL)
		end,
	}

	enter(root)
	emit(bc.label, EOF_LABEL)

	return instructions
end
