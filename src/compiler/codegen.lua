--List of possible bytecode instructions
local bc = {
	label = 0,
	call = 1,
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
	pop_until_null = 13,
	get_cache_else_jump = 14,
	set_cache = 15,
	delete_cache = 16,
	push_catch_loc = 17,
}

require "src.compiler.functions.codes"

local function bc_get_key(code, lookup)
	for k, i in pairs(lookup) do
		if i == code then return k end
	end
	return nil
end

--[[minify-delete]]
---@diagnostic disable-next-line
function print_bytecode(instructions, file)
	local lookup = instructions[#instructions]
	for i = 1, #instructions - 1 do
		local instr = instructions[i]
		local instr_text = bc_get_key(instr[1], bc)
		local call_text = instr[3]

		if (instr[1] == bc.push or instr[1] == bc.set or instr[1] == bc.get) and call_text ~= nil then
			call_text = lookup[call_text]
		end

		if instr[1] == bc.call then
			call_text = bc_get_key(call_text, CALL_CODES)
		end

		if not instr_text then
			parse_error(Span:new(0, 0, 0, 0), 'COMPILER BUG: Unknown bytecode instruction with id ' .. instr[1] .. '!',
				file)
		end

		local line = ''
		if call_text == nil and instr[1] ~= bc.run_command and instr[1] ~= bc.push_cmd_result and instr[1] ~= bc.pop and instr[1] ~= bc.push_index and instr[1] ~= bc.pop_goto_index and instr[1] ~= bc.pop_until_null then
			call_text = 'null'
		elseif call_text == nil then
			call_text = ''
		else
			call_text = std.debug_str(call_text)
		end

		if instr[4] then
			line = i .. ' @ line ' .. instr[2] .. ': ' .. instr_text .. ' ' .. call_text .. ' ' ..
				std.debug_str(instr[4])
		else
			line = i .. ' @ line ' .. instr[2] .. ': ' .. instr_text .. ' ' .. call_text
		end

		if COMPILER_DEBUG then
			if i == DEBUG_INSTRUCTION_NUM then
				line = '\27[7m' .. line .. '\27[0m'
			end
		end

		print(line)
	end
end

--[[/minify-delete]]
---@diagnostic disable-next-line
function generate_bytecode(root, file)
	SHOW_MULTIPLE_ERRORS = false

	local instructions = {}
	local codegen_rules

	local current_line = 0
	local emit_after_labels = {}

	local function emit(instruction_id, param1, param2)
		if instruction_id == bc.call then
			if not CALL_CODES[param1] then
				parse_error(Span:new(current_line, 0, current_line, 0),
					'COMPILER BUG: No call code for function "' .. std.str(param1) .. '"!', file)
			end
			param1 = CALL_CODES[param1]
		end

		table.insert(instructions, { instruction_id, current_line, param1, param2 })

		local instr_text = bc_get_key(instruction_id, bc)
		local call_text = param1
		if instruction_id == bc.call then call_text = bc_get_key(param1, CALL_CODES) end

		if not instr_text then
			parse_error(Span:new(current_line, 0, current_line, 0),
				'COMPILER BUG: Unknown bytecode instruction with id ' .. instruction_id .. '!', file)
		end

		return #instructions
	end

	local function enter(token)
		if not codegen_rules[token.id] then
			parse_error(token.span,
				'COMPILER BUG: Unable to generate bytecode for token of type "' .. token_text(token.id) .. '"!', file)
		end

		current_line = token.span.from.line
		codegen_rules[token.id](token, file)
	end

	local function is_const(token) return token.value ~= nil or token.id == TOK.lit_null end

	local loop_term_labels = {}
	local loop_begn_labels = {}

	--Create a termination label which will be appended to the end
	local EOF_LABEL = LABEL_ID()

	local cache_id = 0
	local cache_ids = {}
	local function get_cache_id(text)
		if not cache_ids[text] then
			cache_ids[text] = cache_id
			cache_id = cache_id + 1
		end
		return cache_ids[text]
	end

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

		[TOK.text] = function(token, file)
			if token.value == nil then
				parse_error(token.span, 'COMPILER BUG: No type found for "text" token!', file)
			end
			emit(bc.push, token.value)
		end,

		--CODEGEN FOR PROGRAM (Just a list of commands/statements)
		[TOK.program] = function(token, file)
			for i = 1, #token.children do
				enter(token.children[i])
			end
		end,

		--CODEGEN FOR COMMANDS
		[TOK.command] = function(token, file)
			--ignore "define" pseudo-command
			if token.children[1].value == 'define' then return end

			local all_const, p = true, {}
			for i = 1, #token.children do
				if not is_const(token.children[i]) then
					all_const = false
					break
				end
				if std.type(token.children[i].value) == 'array' then
					for k = 1, #token.children[i].value do
						table.insert(p, std.str(token.children[i].value[k]))
					end
				elseif std.type(token.children[i].value) == 'object' then
					for key, value in pairs(token.children[i].value) do
						table.insert(p, std.str(key))
						table.insert(p, std.str(value))
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
		[TOK.let_stmt] = function(token, file)
			local label1, label2

			--If this variable
			--1. Is not assigned to results of an inline command eval
			--2. Is not used anywhere
			--3. Is not part of a multi-var assignment where 1 or more vars are in use
			--4. AND we are not running as a REPL
			--Then don't generate the (dead) code for it.
			--[[minify-delete]]
			if not _G['REPL'] then
				--[[/minify-delete]]
				local v1 = token.children[1]
				if v1.ignore and not v1.is_referenced then
					local not_used, multivars = true, v1.children
					if multivars then
						for i = 1, #multivars do
							if multivars[i].is_referenced then
								not_used = false
								break
							end
						end
					end

					if not_used then return end
				end
				--[[minify-delete]]
			end
			--[[/minify-delete]]

			if token.text == 'initial' then
				label1, label2 = LABEL_ID(), LABEL_ID()
				emit(bc.push, token.children[1].text)
				emit(bc.call, 'varexists')
				emit(bc.call, 'jumpiffalse', label1)
				emit(bc.pop)
				emit(bc.call, 'jump', label2)
				emit(bc.label, label1)
				emit(bc.pop)
			end

			if token.children[3] then
				if token.children[3].id == TOK.expr_open then
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
			elseif token.children[2] then
				codegen_rules.recur_push(token.children[2])
			else
				emit(bc.push, nil)
			end

			if token.children[1].children then
				--Multi-var assignment is basically just getting the nth element of the array
				local vars = { token.children[1].text }
				for i = 1, #token.children[1].children do
					table.insert(vars, token.children[1].children[i].text)
				end

				for i = 1, #vars do
					if token.children[2] then
						if i < #vars then emit(bc.copy, 0) end
						emit(bc.push, i)
						emit(bc.call, 'arrayindex')
					else
						if i > 1 then emit(bc.push, nil) end
					end
					emit(bc.set, vars[i])
				end
			else
				emit(bc.set, token.children[1].text)
			end

			if token.text == 'initial' then
				emit(bc.label, label2)
			end
		end,

		--CODEGEN FOR ARRAY CONCATENATION
		[TOK.array_concat] = function(token, file)
			local i
			local has_slices = false
			for i = 1, #token.children do
				local chid = token.children[i].id
				if chid == TOK.array_slice or token.children[i].reduce_array_concat then has_slices = true end
				codegen_rules.recur_push(token.children[i])
			end

			if has_slices then
				emit(bc.call, 'superimplode', #token.children)
			else
				emit(bc.call, 'implode', #token.children)
			end
		end,

		--ARRAY SLICE
		[TOK.array_slice] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			if token.children[2] then
				codegen_rules.recur_push(token.children[2])
			else
				--non-terminated slices
				--get length from previous item on the stack
				emit(bc.copy, 1)
				emit(bc.call, 'length')
			end
			emit(bc.call, 'arrayslice')
		end,

		--STRING CONCAT
		[TOK.concat] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			if token.children[2] then codegen_rules.recur_push(token.children[2]) end
			emit(bc.call, 'concat', #token.children)
		end,

		--CODEGEN FOR VARIABLES
		[TOK.variable] = function(token, file)
			if LIST_COMP_VAR[token.text] then
				emit(bc.get, LIST_COMP_VAR[token.text])
			else
				emit(bc.get, token.text)
			end
		end,

		--DELETE STATEMENT
		[TOK.delete_stmt] = function(token, file)
			local i
			for i = 1, #token.children do
				emit(bc.delete, token.children[i].text)
			end
		end,

		--STRING CONCATENATION
		[TOK.string_open] = function(token, file)
			if #token.children > 0 then
				local i
				for i = 1, #token.children do
					codegen_rules.recur_push(token.children[i])
				end
				emit(bc.call, 'concat', #token.children)
			elseif token.value ~= nil then
				emit(bc.push, token.value)
			else
				parse_error(token.span, 'COMPILER BUG: Codegen for "string_open", token has no children or const value!',
					file)
			end
		end,

		--EXPONENT OPERATIONS
		[TOK.exponent] = function(token, file)
			codegen_rules.binary_op(token, 'pow')
		end,

		--MULTIPLICATION OPERATIONS
		[TOK.multiply] = function(token, file)
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
		[TOK.add] = function(token, file)
			local op = {
				['+'] = 'add',
				['-'] = 'sub',
			}
			codegen_rules.binary_op(token, op[token.text])
		end,

		--NEGATE
		[TOK.negate] = function(token, file)
			--No real negate operation, it's just zero minus the value
			emit(bc.push, 0)
			codegen_rules.recur_push(token.children[1])
			emit(bc.call, 'sub')
		end,

		--LENGTH OPERATOR
		[TOK.length] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			emit(bc.call, 'length')
		end,

		--INDEXING
		[TOK.index] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			codegen_rules.recur_push(token.children[2])
			emit(bc.call, 'arrayindex')
		end,

		--BOOLEAN OPERATIONS
		[TOK.boolean] = function(token, file)
			local op = {
				['and'] = 'booland',
				['or'] = 'boolor',
				['xor'] = 'boolxor',
				['not'] = 'boolnot',
				['in'] = 'inarray',
				['like'] = 'strlike',
				['exists'] = 'varexists',
			}
			local shortcut = {
				['and'] = function(c1, c2)
					local shortcut = LABEL_ID()
					codegen_rules.recur_push(c1)
					emit(bc.call, 'bool')
					emit(bc.call, 'jumpiffalse', shortcut)
					emit(bc.pop)
					codegen_rules.recur_push(c2)
					emit(bc.call, 'bool')
					emit(bc.label, shortcut)
				end,
				['or'] = function(c1, c2)
					local shortcut = LABEL_ID()
					codegen_rules.recur_push(c1)
					emit(bc.call, 'boolnot')
					emit(bc.call, 'jumpiffalse', shortcut)
					emit(bc.pop)
					codegen_rules.recur_push(c2)
					emit(bc.call, 'boolnot')
					emit(bc.label, shortcut)
					emit(bc.call, 'boolnot')
				end,
			}
			--[[minify-delete]]
			if _G['NO_SHORTCUT'] then shortcut = {} end
			--[[/minify-delete]]

			if #token.children > 1 then
				local s = shortcut[token.text]
				if s then
					s(token.children[1], token.children[2])
				else
					codegen_rules.binary_op(token, op[token.text])
				end
			else
				codegen_rules.recur_push(token.children[1])
				emit(bc.call, op[token.text])
			end
		end,

		--COMPARISON OPERATIONS (also boolean technically)
		[TOK.comparison] = function(token, file)
			local op = {
				['='] = 'equal',
				['!='] = 'notequal',
				['>'] = 'greater',
				['>='] = 'greaterequal',
				['<'] = 'less',
				['<='] = 'lessequal',
				['like'] = 'strlike',
				['in'] = 'inarray',
			}
			codegen_rules.binary_op(token, op[token.text])
		end,

		--FOR LOOPS
		[TOK.for_stmt] = function(token, file)
			local loop_beg_label = LABEL_ID()
			local loop_end_label = LABEL_ID()

			--Try to optimize away for loops with no body and with a knowable stop point
			if token.children[3] == nil then
				local list = token.children[2]
				--If list is entirely constant, just use the last value.
				--[[minify-delete]]
				if not _G['KEEP_DEAD_CODE'] then --[[/minify-delete]]
					if is_const(list) then
						local val = list.value
						if val ~= nil then
							if std.type(val) == 'array' then
								val = val[#val]
							elseif std.type(val) == 'object' then
								local v
								for key, value in pairs(val) do v = key end
								val = v
							end
							emit(bc.push, val)
							emit(bc.set, token.children[1].text)
						end
						return
					end
					--[[minify-delete]]
				end --[[/minify-delete]]

				--Optimize out slices
				--This does not optimize for size, but rather run time.
				--The tradeoff here is that the generated code is 1 instruction more than an un-optimized version, but reduces loop to constant run time.
				--For large slices, this can save a massive amount of time.
				if list.id == TOK.array_slice then
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
			if instructions[#instructions][3] == CALL_CODES.implode then
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
			emit(bc.pop_until_null)
			table.remove(loop_term_labels)
			table.remove(loop_begn_labels)
		end,

		--KEY-VALUE FOR LOOPS
		[TOK.kv_for_stmt] = function(token, file)
			local loop_beg_label = LABEL_ID()
			local loop_end_label = LABEL_ID()

			--Loop setup
			emit(bc.push, nil)
			codegen_rules.recur_push(token.children[3])

			--SMALL OPTIMIZATION:
			--If previously emitted token was an "implode" and then we're "exploding"
			--Just remove the previous token!
			if instructions[#instructions][4] == CALL_CODES.implode then
				table.remove(instructions)
			else
				emit(bc.call, 'explode')
			end
			emit(bc.label, loop_beg_label)
			emit(bc.call, 'explode')
			table.insert(loop_term_labels, loop_end_label)
			table.insert(loop_begn_labels, loop_beg_label)

			--Run loop
			emit(bc.call, 'jumpifnil', loop_end_label)
			emit(bc.set, token.children[1].text)
			emit(bc.set, token.children[2].text)

			if token.children[4] then enter(token.children[4]) end

			--End of loop
			emit(bc.call, 'jump', loop_beg_label)
			emit(bc.label, loop_end_label)
			emit(bc.pop_until_null)
			table.remove(loop_term_labels)
			table.remove(loop_begn_labels)
		end,

		--WHILE LOOPS
		[TOK.while_stmt] = function(token, file)
			local loop_beg_label = LABEL_ID()
			local loop_end_label = LABEL_ID()

			local const = is_const(token.children[1])
			local val = std.bool(token.children[1].value)

			--If the loop will never get executed, don't generate it.
			--[[minify-delete]]
			if not _G['KEEP_DEAD_CODE'] then --[[/minify-delete]]
				if const and not val then return end
				--[[minify-delete]]
			end --[[/minify-delete]]

			--Loop setup
			emit(bc.label, loop_beg_label)
			table.insert(loop_term_labels, loop_end_label)
			table.insert(loop_begn_labels, loop_beg_label)

			--If loop conditional is known to be truey, don't even compare it at run-time.
			if not const or not val then
				--Loop conditional
				codegen_rules.recur_push(token.children[1])
				emit(bc.call, 'jumpiffalse', loop_end_label)
				emit(bc.pop)
			end

			if #token.children >= 2 then
				enter(token.children[2])
			end

			--End of loop
			emit(bc.call, 'jump', loop_beg_label)
			emit(bc.label, loop_end_label)
			emit(bc.pop)
			table.remove(loop_term_labels)
			table.remove(loop_begn_labels)
		end,

		--LIST COMPREHENSION
		[TOK.list_comp] = function(token, file)
			local loop_beg_label = LABEL_ID()
			local loop_end_label = LABEL_ID()
			local loop_var = LABEL_ID()

			local orig_v = token.children[2].text
			LIST_COMP_VAR[orig_v] = LABEL_ID()

			--Loop setup
			emit(bc.push, nil)
			codegen_rules.recur_push(token.children[3]) --list to pull from

			--Initialize loop var
			emit(bc.push, {})
			emit(bc.set, loop_var)

			--SMALL OPTIMIZATION:
			--If previously emitted token was an "implode" and then we're "exploding"
			--Just remove the previous token!
			if instructions[#instructions][3] == CALL_CODES.implode then
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
				local true_label = LABEL_ID()
				local false_label = LABEL_ID()
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
		[TOK.break_stmt] = function(token, file)
			for i = 2, token.children[1].value do
				emit(bc.pop_until_null)
			end
			emit(bc.call, 'jump', loop_term_labels[#loop_term_labels - token.children[1].value + 1])
		end,

		--CONTINUE STATEMENT
		[TOK.continue_stmt] = function(token, file)
			for i = 2, token.children[1].value do
				emit(bc.pop_until_null)
			end
			emit(bc.call, 'jump', loop_begn_labels[#loop_begn_labels - token.children[1].value + 1])
		end,

		--INLINE COMMAND EVALUATION
		[TOK.inline_command] = function(token, file)
			enter(token.children[1])
			emit(bc.push_cmd_result)
		end,

		--IF STATEMENT
		[TOK.if_stmt] = function(token, file)
			local const = is_const(token.children[1])
			local val = std.bool(token.children[1].value)
			local endif_label

			--[[minify-delete]]
			if _G['KEEP_DEAD_CODE'] then const = false end --[[/minify-delete]]

			local has_else = #token.children > 2 and token.children[3].id ~= TOK.kwd_end and not (const and val)

			--Only generate the branch if it's possible for it to execute.
			if not const or val then
				local else_label

				--Don't generate a label if the "if" part will always execute
				if not const then
					else_label = LABEL_ID()
					endif_label = LABEL_ID()
					if token.children[1].id == TOK.gosub_stmt then token.children[1].dynamic = true end
					enter(token.children[1])
					emit(bc.call, 'jumpiffalse', else_label)
					emit(bc.pop)
				end

				--IF statement body
				if token.children[2].id ~= TOK.kwd_then then
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
				if else_block.id == TOK.else_stmt then
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
		[TOK.elif_stmt] = function(token, file) codegen_rules[TOK.if_stmt](token, file) end,

		--GOSUB STATEMENT
		[TOK.gosub_stmt] = function(token, file)
			--[[minify-delete]]
			if not _G['KEEP_DEAD_CODE'] then --[[/minify-delete]]
				if token.ignore then return end
				--[[minify-delete]]
			end --[[/minify-delete]]

			--Push any parameters passed to the gosub
			if #token.children > 1 then
				for i = 2, #token.children do
					codegen_rules.recur_push(token.children[i])
				end
				emit(bc.call, 'implode', #token.children - 1)
			else
				emit(bc.push, {})
			end

			if token.dynamic then
				local i
				local end_label, label_var = LABEL_ID(), LABEL_ID()
				codegen_rules.recur_push(token.children[1])
				emit(bc.push_index)
				emit(bc.call, 'jump', '?dynamic-gosub')

				emit_after_labels['dynamic-gosub'] = function(labels)
					emit(bc.call, 'jump', EOF_LABEL)
					emit(bc.label, '?dynamic-gosub')

					local names, indexes = {}, {}
					for name, index in pairs(labels) do
						if name:sub(1, 1) ~= '?' then
							table.insert(names, name)
							table.insert(indexes, index - 1)
						end
					end

					emit(bc.push, names)
					emit(bc.swap)
					emit(bc.call, 'implode', 2)
					emit(bc.call, 'index')

					--If the label doesn't exist in the program, leave zero on the stack, and go back to the caller.
					local fail_label = LABEL_ID()
					emit(bc.call, 'jumpiffalse', fail_label)

					--If the label DOES exist, jump to the appropriate index
					emit(bc.push, indexes)
					emit(bc.swap)
					emit(bc.call, 'arrayindex')
					emit(bc.push_index)
					emit(bc.call, 'jump') --JUMP without param will pop the param from the stack

					--Then push TRUE and return to caller
					emit(bc.pop)
					emit(bc.push, true)

					emit(bc.label, fail_label)
					emit(bc.pop_goto_index, true) --Unlike regular subroutines, don't clean up the stack here.
				end
			elseif is_const(token.children[1]) then
				emit(bc.push_index)
				emit(bc.call, 'jump', token.children[1].text)
			else
				parse_error(token.span, 'Label for gosub must either be a constant, or wrapped inside an if statement',
					file)
			end
		end,

		--SUBROUTINES. These are basically just a label and a return statement
		[TOK.subroutine] = function(token, file)
			--Don't generate code for the subroutine if it contains nothing.
			--If it contains nothing then references to it have already been removed.
			if not token.ignore and token.is_referenced --[[minify-delete]] or _G['KEEP_DEAD_CODE'] --[[/minify-delete]] then
				local skipsub = LABEL_ID()
				emit(bc.call, 'jump', skipsub)
				emit(bc.label, token.text)

				if token.memoize then
					local no_cache = LABEL_ID()
					emit(bc.get_cache_else_jump, get_cache_id(token.text), no_cache)

					--If cached, just use the cache value and return
					emit(bc.pop_goto_index)
					emit(bc.label, no_cache)

					--If not cached, set up a return point so value can be cached
					local use_cache = LABEL_ID()
					emit(bc.push_index)
					emit(bc.call, 'jump', use_cache)

					--Set cache and return
					emit(bc.set_cache, get_cache_id(token.text))
					emit(bc.pop_goto_index)

					emit(bc.label, use_cache)
				end
				--Subroutine body
				enter(token.children[1])

				--Make sure to push a value to the stack before returning
				--TODO: optimize this away if return is guaranteed
				emit(bc.push, nil)
				emit(bc.pop_goto_index)
				emit(bc.label, skipsub)
			end
		end,

		--RETURN STATEMENT
		[TOK.return_stmt] = function(token, file)
			if #token.children == 0 then
				emit(bc.push, nil)
			else
				for i = 1, #token.children do
					codegen_rules.recur_push(token.children[i])
				end
				if #token.children > 1 then
					emit(bc.call, 'implode', #token.children)
				end
			end

			emit(bc.pop_goto_index)
		end,

		--BUILT-IN FUNCTION CALLS
		[TOK.func_call] = function(token, file)
			--Handle the reduce() function differently.
			--It's actually a loop that acts on all the elements.
			if token.text == 'reduce' then
				local op_id = token.children[2].id

				if op_id == TOK.op_plus then
					--built-in function for sum of list elements
					token.text = 'sum'
					token.children[2] = nil
				elseif op_id == TOK.op_times then
					--built-in function for multiplying list elements
					token.text = 'mult'
					token.children[2] = nil
				else
					--If there are no built-in functions for this type of reduce, emulate it.
					local loop_beg_label = LABEL_ID()
					local loop_end_label = LABEL_ID()
					local loop_skip_label = LABEL_ID()

					emit(bc.push, nil)
					codegen_rules.recur_push(token.children[1])
					emit(bc.call, 'explode')
					emit(bc.call, 'jumpifnil', loop_end_label) --Skip entirely if array is null
					emit(bc.label, loop_beg_label)
					emit(bc.swap)
					emit(bc.call, 'jumpifnil', loop_end_label)

					if op_id == TOK.op_idiv then
						emit(bc.call, 'div')
						emit(bc.call, 'implode', 1)
						emit(bc.call, 'floor')
					else
						local ops = {
							[TOK.op_plus] = 'add',
							[TOK.op_minus] = 'sub',
							[TOK.op_times] = 'mul',
							[TOK.op_div] = 'div',
							[TOK.op_mod] = 'rem',
							[TOK.op_and] = 'booland',
							[TOK.op_or] = 'boolor',
							[TOK.op_xor] = 'boolxor',
							[TOK.op_eq] = 'equal',
							[TOK.op_ne] = 'notequal',
							[TOK.op_gt] = 'greater',
							[TOK.op_ge] = 'greaterequal',
							[TOK.op_lt] = 'less',
							[TOK.op_le] = 'lessequal',
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
				if chid == TOK.array_slice or token.children[i].reduce_array_concat then has_slices = true end
				codegen_rules.recur_push(token.children[i])
			end

			emit(bc.call, 'implode', #token.children)
			emit(bc.call, token.text)
		end,

		--STOP statement
		[TOK.kwd_stop] = function(token, file)
			emit(bc.call, 'jump', EOF_LABEL)
		end,

		--TERNARY (X if Y else Z) operator
		[TOK.ternary] = function(token, file)
			local else_label = LABEL_ID()
			local endif_label = LABEL_ID()

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

		--OBJECT CONSTRUCTION
		[TOK.object] = function(token, file)
			emit(bc.push, std.object())

			for i = 1, #token.children do
				codegen_rules.recur_push(token.children[i])
				emit(bc.call, 'implode', 3)
				emit(bc.call, 'update')
			end
		end,

		--KEY-VALUE PAIR
		[TOK.key_value_pair] = function(token, file)
			codegen_rules.recur_push(token.children[1])
			codegen_rules.recur_push(token.children[2])
		end,

		--BREAK CACHE OF SUBROUTINE
		[TOK.uncache_stmt] = function(token, file)
			emit(bc.delete_cache, get_cache_id(token.children[1].text))
		end,

		--Ignore "using X as Y" statements
		[TOK.alias_stmt] = function(token, file) end,

		--CATCH ERRORS
		[TOK.try_stmt] = function(token, file)
			local catch_label = LABEL_ID()
			local end_label = LABEL_ID()

			emit(bc.push_catch_loc, catch_label)
			enter(token.children[1]) --At run-time, any 'error' command will jump to the catch block
			emit(bc.call, 'jump', end_label) --If no error, skip the catch block
			emit(bc.label, catch_label)

			--If we're assigning the error to a variable, do so.
			--Othersise just ignore the error message.
			if token.children[3] then
				emit(bc.set, token.children[3].text)
			else
				emit(bc.pop)
			end

			--Run the catch block
			if token.children[2].id ~= TOK.kwd_end then
				enter(token.children[2])
			end

			emit(bc.label, end_label)
		end,
	}

	enter(root)

	--BUILD LABEL LISTS AND EMIT DYNAMIC GOSUB CODE BASED ON THAT
	local labels, ct = {}, 1
	for i = 1, #instructions do
		local instr = instructions[i]
		if instr[1] == bc.label then
			labels[instr[3]] = ct
		else
			ct = ct + 1
		end
	end
	local old_instr_ct = #instructions
	for i, routine in pairs(emit_after_labels) do
		routine(labels)
	end

	emit(bc.label, EOF_LABEL)
	for i = old_instr_ct + 1, #instructions do
		local instr = instructions[i]
		if instr and instr[1] == bc.label then
			labels[instr[3]] = ct
		else
			ct = ct + 1
		end
	end

	--CLEAN OUT LABEL PSEUDO-COMMANDS
	local result2 = {}
	for i = 1, #instructions do
		local instr = instructions[i]
		if instr[1] ~= bc.label then
			table.insert(result2, instr)
		end
	end

	local constants = {} --lookup table for constants to reduce output file size
	local reverse_constants = {}
	local const_len = 0
	local result = {}
	for i = 1, #result2 do
		local instr = result2[i]
		--CLEAN OUT LABEL REFERENCES
		if (instr[1] == bc.call and (instr[3] == CALL_CODES.jump or instr[3] == CALL_CODES.jumpifnil or instr[3] == CALL_CODES.jumpiffalse)) or instr[1] == bc.get_cache_else_jump or instr[1] == bc.push_catch_loc then
			local ix = 4
			if instr[1] == bc.push_catch_loc then ix = 3 end

			if instr[ix] ~= nil then
				if labels[instr[ix]] == nil then
					parse_error(Span:new(instr[2], 0, instr[2], 0),
						'COMPILER BUG: Attempt to reference unknown label of ID "' .. std.str(instr[ix]) .. '"!', file)
				end

				instr[ix] = labels[instr[ix]] - 1
			end
		end

		--Output constants to lookup table
		if (instr[1] == bc.set or instr[1] == bc.get or instr[1] == bc.push or instr[1] == bc.delete) and instr[3] ~= nil then
			local text = json.stringify(instr[3])
			if constants[text] == nil then
				const_len = const_len + 1
				constants[text] = const_len
				reverse_constants[const_len] = instr[3]
			end

			instr[3] = constants[text]
		end

		table.insert(result, instr)
	end

	if #result then
		table.insert(result, reverse_constants)
	end
	return result
end
