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
	copy = 10,
	delete = 11,
	swap = 12,
}

local call_codes = {
	jump = 0,
	jumpifnil = 1,
	jumpiffalse = 2,
	explode = 3,
	implode = 4,
	superimplode = 5,
	add = 6,
	sub = 7,
	mul = 8,
	div = 9,
	rem = 10,
	length = 11,
	arrayindex = 12,
	arrayslice = 13,
	concat = 14,
	booland = 15,
	boolor = 16,
	boolxor = 17,
	inarray = 18,
	strlike = 19,
	equal = 20,
	notequal = 21,
	greater = 22,
	greaterequal = 23,
	less = 24,
	lessequal = 25,
	boolnot = 26,
	varexists = 27,
	irandom = 28,
	frandom = 29,
	worddiff = 30,
	dist = 31,
	sin = 32,
	cos = 33,
	tan = 34,
	asin = 35,
	acos = 36,
	atan = 37,
	atan2 = 38,
	sqrt = 39,
	sum = 40,
	mult = 41,
	pow = 42,
	min = 43,
	max = 44,
	split = 45,
	join = 46,
	type = 47,
	bool = 48,
	num = 49,
	str = 50,
	array = 51,
	floor = 52,
	ceil = 53,
	round = 54,
	abs = 55,
	append = 56,
	index = 57,
	lower = 58,
	upper = 59,
	camel = 60,
	replace = 61,
	json_encode = 62,
	json_decode = 63,
	json_valid = 64,
	b64_encode = 65,
	b64_decode = 66,
	lpad = 67,
	rpad = 68,
	hex = 69,
	filter = 70,
	isnumber = 71,
	clocktime = 72,
	reverse = 73,
	sort = 74,
	bytes = 75,
	frombytes = 76,
	merge = 77,
	update = 78,
	insert = 79,
	delete = 80,
	lerp = 81,
}

local function bc_get_key(code, lookup)
	local i, k
	for k, i in pairs(lookup) do
		if i == code then return k end
	end
	return nil
end

function print_bytecode(instructions)
	local i
	for i = 1, #instructions do
		local instr = instructions[i]
		local instr_text = bc_get_key(instr[1], bc)
		local call_text = instr[3]
		if instr[1] == bc.call then
			call_text = bc_get_key(call_text, call_codes)
		end

		if not instr_text then
			parse_error(0, 0, 'COMPILER BUG: Unknown bytecode instruction with id '..instr[1]..'!', file)
		end

		local line = ''
		if call_text == nil and instr[1] ~= bc.run_command and instr[1] ~= bc.push_cmd_result and instr[1] ~= bc.pop and instr[1] ~= bc.push_index and instr[1] ~= bc.pop_goto_index then
			call_text = 'null'
		elseif call_text == nil then
			call_text = ''
		else
			call_text = std.debug_str(call_text)
		end

		if instr[4] then
			line = i..' @ line '..instr[2]..': '..instr_text..' '..call_text..' '..std.debug_str(instr[4])
		else
			line = i..' @ line '..instr[2]..': '..instr_text..' '..call_text
		end

		if COMPILER_DEBUG then
			if i == DEBUG_INSTRUCTION_NUM then
				line = '\27[7m' .. line .. '\27[0m'
			end
		end

		print(line)
	end
end

function generate_bytecode(root, file)
	local instructions = {}
	local codegen_rules

	local current_line = 0

	local function emit(instruction_id, param1, param2)
		if instruction_id == bc.call then
			if not call_codes[param1] then
				parse_error(current_line, 0, 'COMPILER BUG: No call code for function "'..std.str(param1)..'"!', file)
			end
			param1 = call_codes[param1]
		end

		table.insert(instructions, {instruction_id, current_line, param1, param2})

		local instr_text = bc_get_key(instruction_id, bc)
		local call_text = param1
		if instruction_id == bc.call then call_text = bc_get_key(param1, call_codes) end

		if not instr_text then
			parse_error(current_line, 0, 'COMPILER BUG: Unknown bytecode instruction with id '..instruction_id..'!', file)
		end

		--TEMP: print code as it's generated
		-- if COMPILER_DEBUG then
		-- 	if call_text == nil and instruction_id ~= bc.run_command and instruction_id ~= bc.push_cmd_result and instruction_id ~= bc.pop and instruction_id ~= bc.push_index and instruction_id ~= bc.pop_goto_index then call_text = 'null' else call_text = std.debug_str(call_text) end
		-- 	if param2 then
		-- 		print(current_line..': '..instr_text..' '..call_text..' '..std.debug_str(param2))
		-- 	else
		-- 		print(current_line..': '..instr_text..' '..call_text)
		-- 	end
		-- end

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

	local LIST_COMP_VAR = {}

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
			--ignore "define" pseudo-command
			if token.children[1].value == 'define' then return end

			local all_const, p, i = true, {}
			for i = 1, #token.children do
				if not is_const(token.children[i]) then
					all_const = false
					break
				end
				if type(token.children[i].value) == 'table' then
					local k
					for k = 1, #token.children[i].value do
						table.insert(p, std.str(token.children[i].value[k]))
					end
				else
					table.insert(p, std.str(token.children[i].value))
				end
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
			if token.children[3] then
				if token.children[3].id == tok.expr_open then
					--Append to variable
					emit(bc.get, token.children[1].text)
					emit(bc.push, -1)
					codegen_rules.recur_push(token.children[2])
					emit(bc.call, 'implode', 3)
					emit(bc.call, 'insert')
				else
					--Update element of variable
					emit(bc.get, token.children[1].text)
					codegen_rules.recur_push(token.children[3])
					codegen_rules.recur_push(token.children[2])
					emit(bc.call, 'implode', 3)
					emit(bc.call, 'update')
				end
			else
				codegen_rules.recur_push(token.children[2])
			end
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
			if token.children[2] then codegen_rules.recur_push(token.children[2]) end
			emit(bc.call, 'concat', #token.children)
		end,

		--CODEGEN FOR VARIABLES
		[tok.variable] = function(token, file)
			if LIST_COMP_VAR[token.text] then
				emit(bc.get, LIST_COMP_VAR[token.text])
			else
				emit(bc.get, token.text)
			end
		end,

		--DELETE STATEMENT
		[tok.delete_stmt] = function(token, file)
			local i
			for i = 1, #token.children do
				emit(bc.delete, token.children[i].text)
			end
		end,

		--STRING CONCATENATION
		[tok.string_open] = function(token, file)
			if #token.children > 0 then
				local i
				for i = 1, #token.children do
					codegen_rules.recur_push(token.children[i])
				end
				emit(bc.call, 'concat', #token.children)
			elseif token.value ~= nil then
				emit(bc.push, token.value)
			else
				parse_error(token.line, token.col, 'COMPILER BUG: Codegen for "string_open", token has no children or const value!', file)
			end
		end,

		--MULTIPLICATION OPERATIONS
		[tok.multiply] = function(token, file)
			if token.text == '//' then
				--No such thing as integer division really, it's just division, rounded down.
				codegen_rules.binary_op(token, 'div')
				emit(bc.call, 'implode', 1)
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
			emit(bc.call, 'arrayindex')
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
				['='] = 'equal',
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

			--Try to optimize away for loops with no body and with a knowable stop point
			if token.children[3] == nil then
				local list = token.children[2]
				--If list is entirely constant, just use the last value.
				if is_const(list) then
					local val = list.value
					if type(val) == 'table' then val = val[#val] end
					emit(bc.push, val)
					emit(bc.set, token.children[1].text)
					return
				end

				--Optimize out slices
				--This does not optimize for size, but rather run time.
				--The tradeoff here is that the generated code is 1 instruction more than an un-optimized version, but reduces loop to constant run time.
				--For large slices, this can save a massive amount of time.
				if list.id == tok.array_slice then
					--If list is a slice with constant values, optimize it away.
					if is_const(list.children[1]) and is_const(list.children[2]) then
						local start, stop = list.children[1].value, list.children[2].value

						--The variable will never get set in this case
						if start > stop then return end

						emit(bc.push, stop)
						emit(bc.set, token.children[1].text)
						return
					end

					--Otherwise, we can still optimize out slices
					codegen_rules.recur_push(list.children[2])
					codegen_rules.recur_push(list.children[1])
					emit(bc.copy, 1) -- copy list.children[2] onto stack again
					--Check if var would even get set
					emit(bc.call, 'lessequal')
					emit(bc.call, 'jumpiffalse', loop_end_label)
					--If so, set it
					emit(bc.pop)
					emit(bc.set, token.children[1].text)
					emit(bc.call, 'jump', loop_beg_label)
					emit(bc.label, loop_end_label)
					emit(bc.pop)
					emit(bc.label, loop_beg_label)
					return
				end
			end

			--Loop setup
			emit(bc.push, nil)
			codegen_rules.recur_push(token.children[2])

			--SMALL OPTIMIZATION:
			--If previously emitted token was an "implode" and then we're "exploding"
			--Just remove the previous token!
			if instructions[#instructions][3] == call_codes.implode then
				table.remove(instructions)
			else
				emit(bc.call, 'explode')
			end
			emit(bc.label, loop_beg_label)
			table.insert(loop_term_labels, loop_end_label)
			table.insert(loop_begn_labels, loop_beg_label)

			--Run loop
			emit(bc.call, 'jumpifnil', loop_end_label)
			emit(bc.set, token.children[1].text)

			if token.children[3] then enter(token.children[3]) end

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

		--LIST COMPREHENSION
		[tok.list_comp] = function(token, file)
			local loop_beg_label = label_id()
			local loop_end_label = label_id()
			local loop_var = label_id()

			local orig_v = token.children[2].text
			LIST_COMP_VAR[orig_v] = label_id()

			--Loop setup
			emit(bc.push, nil)
			codegen_rules.recur_push(token.children[3]) --list to pull from

			--Initialize loop var
			emit(bc.push, {})
			emit(bc.set, loop_var)

			--SMALL OPTIMIZATION:
			--If previously emitted token was an "implode" and then we're "exploding"
			--Just remove the previous token!
			if instructions[#instructions][3] == call_codes.implode then
				table.remove(instructions)
			else
				emit(bc.call, 'explode')
			end
			emit(bc.label, loop_beg_label)
			table.insert(loop_term_labels, loop_end_label)
			table.insert(loop_begn_labels, loop_beg_label)

			--Run loop
			emit(bc.call, 'jumpifnil', loop_end_label)
			emit(bc.set, LIST_COMP_VAR[orig_v]) --set the loop iter variable

			if token.children[4] then
				--Only add the value to the list if the condition is met.
				codegen_rules.recur_push(token.children[4])
				true_label = label_id()
				false_label = label_id()
				emit(bc.call, 'jumpiffalse', false_label)
				emit(bc.pop)
				emit(bc.call, 'jump', true_label)
				emit(bc.label, false_label)
				emit(bc.pop)
				emit(bc.call, 'jump', loop_beg_label)
				emit(bc.label, true_label)
			end

			--Emit the output expression
			codegen_rules.recur_push(token.children[1])
			emit(bc.set, LIST_COMP_VAR[orig_v])

			--append it to the loop var
			emit(bc.get, loop_var)
			emit(bc.get, LIST_COMP_VAR[orig_v])
			emit(bc.call, 'implode', 2)
			emit(bc.call, 'append')
			emit(bc.set, loop_var)

			-- if token.children[3] then enter(token.children[3]) end

			--End of loop
			emit(bc.call, 'jump', loop_beg_label)
			emit(bc.label, loop_end_label)
			emit(bc.pop)
			emit(bc.get, loop_var)
			emit(bc.delete, loop_var)

			table.remove(loop_term_labels)
			table.remove(loop_begn_labels)
			LIST_COMP_VAR[orig_v] = nil
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

			local has_else = #token.children > 2 and token.children[3].id ~= tok.kwd_end and not (const and val)

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
				if token.children[2].id ~= tok.kwd_then then
					enter(token.children[2])
				end

				if not const then emit(bc.call, 'jump', endif_label) end

				--Jump to here if "if" section does not execute
				if not const then
					emit(bc.label, else_label)
					emit(bc.pop)
				end
			end

			--Generate the "else" part of the if statement
			--Only if it's possible for the "if" part to not execute.
			if has_else then
				local else_block = token.children[3]
				if else_block.id == tok.else_stmt then
					if else_block.children and #else_block.children > 0 then
						enter(else_block.children[1])
					end
				else
					enter(else_block)
				end
			end

			if not const then emit(bc.label, endif_label) end

		end,

		--ELIF STATEMENT (Functionally identical to the IF statement)
		[tok.elif_stmt] = function(token, file) codegen_rules[tok.if_stmt](token, file) end,

		--GOSUB STATEMENT
		[tok.gosub_stmt] = function(token, file)
			if token.ignore then return end

			if is_const(token.children[1]) then
				emit(bc.push_index)
				emit(bc.call, 'jump', token.children[1].text)
			else
				parse_error(token.line, token.col, 'Label for gosub must either be a constant, or wrapped inside an if statement', file)
			end
		end,

		--SUBROUTINES. These are basically just a label and a return statement
		[tok.subroutine] = function(token, file)
			--Don't generate code for the subroutine if it contains nothing.
			--If it contains nothing then references to it have already been removed.
			if not token.ignore then
				local skipsub = label_id()
				emit(bc.call, 'jump', skipsub)
				emit(bc.label, token.text)
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
			--Handle the reduce() function differently.
			--It's actually a loop that acts on all the elements.
			if token.text == 'reduce' then
				local op_id = token.children[2].id

				if op_id == tok.op_plus then
					--built-in function for sum of list elements
					token.text = 'sum'
					token.children[2] = nil
				elseif op_id == tok.op_times then
					--built-in function for multiplying list elements
					token.text = 'mult'
					token.children[2] = nil
				else
					--If there are no built-in functions for this type of reduce, emulate it.
					loop_beg_label = label_id()
					loop_end_label = label_id()
					loop_skip_label = label_id()

					emit(bc.push, nil)
					codegen_rules.recur_push(token.children[1])
					emit(bc.call, 'explode')
					emit(bc.call, 'jumpifnil', loop_end_label) --Skip entirely if array is null
					emit(bc.label, loop_beg_label)
					emit(bc.swap)
					emit(bc.call, 'jumpifnil', loop_end_label)

					if op_id == tok.op_idiv then
						emit(bc.call, 'div')
						emit(bc.call, 'implode', 1)
						emit(bc.call, 'floor')
					else
						ops = {
							[tok.op_plus] = 'add',
							[tok.op_minus] = 'sub',
							[tok.op_times] = 'mul',
							[tok.op_div] = 'div',
							[tok.op_mod] = 'rem',
							[tok.op_and] = 'booland',
							[tok.op_or] = 'boolor',
							[tok.op_xor] = 'boolxor',
							[tok.op_eq] = 'equal',
							[tok.op_ne] = 'notequal',
							[tok.op_gt] = 'greater',
							[tok.op_ge] = 'greaterequal',
							[tok.op_lt] = 'less',
							[tok.op_le] = 'lessequal',
						}
						emit(bc.call, ops[op_id])
					end
					emit(bc.call, 'jump', loop_beg_label)
					emit(bc.label, loop_end_label)
					emit(bc.pop)
					emit(bc.label, loop_skip_label)

					return
				end
			end

			--Normal functions call the respective function logic at run time.
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

		--TERNARY (X if Y else Z) operator
		[tok.ternary] = function(token, file)
			local else_label = label_id()
			local endif_label = label_id()

			codegen_rules.recur_push(token.children[1])
			emit(bc.call, 'jumpiffalse', else_label)
			emit(bc.pop)
			codegen_rules.recur_push(token.children[2])
			emit(bc.call, 'jump', endif_label)
			emit(bc.label, else_label)
			emit(bc.pop)
			codegen_rules.recur_push(token.children[3])
			emit(bc.label, endif_label)
		end,
	}

	enter(root)
	emit(bc.label, EOF_LABEL)

	--CLEAN OUT LABEL PSEUDO-COMMANDS
	local labels, result2, ct, i = {}, {}, 1
	for i = 1, #instructions do
		local instr = instructions[i]
		if instr[1] == bc.label then
			labels[instr[3]] = ct
		else
			ct = ct + 1
			table.insert(result2, instr)
		end
	end

	--CLEAN OUT LABEL REFERENCES
	local result = {}
	for i = 1, #result2 do
		local instr = result2[i]
		if instr[1] == bc.call and (instr[3] == call_codes.jump or instr[3] == call_codes.jumpifnil or instr[3] == call_codes.jumpiffalse) then
			if labels[instr[4]] == nil then
				parse_error(instr[2], 0, 'COMPILER BUG: Attempt to reference unknown label of ID "'..std.str(instr[4])..'"!', file)
			end

			instr[4] = labels[instr[4]] - 1
		end

		table.insert(result, instr)
	end

	return result
end
