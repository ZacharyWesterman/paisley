require "src.compiler.functions.params"
require "src.compiler.functions.types"

FILE_CACHE = {}
--[[minfy-delete]]
ALIASES_TOPLEVEL = { {} }
MACROS_TOPLEVEL = { {} }
--[[/minify-delete]]

function SemanticAnalyzer(root, root_file)
	--[[minify-delete]]
	SHOW_MULTIPLE_ERRORS = true
	--[[/minify-delete]]

	---@param root Token
	---@param token_ids TOK[]
	---@param operation fun(token: Token, file: string?)?
	---@param on_exit fun(token: Token, file: string?)?
	local function recurse(root, token_ids, operation, on_exit, file)
		if file == nil then file = root_file end
		if root.filename then file = root.filename end

		local correct_token = false
		for _, id in ipairs(token_ids) do
			if root.id == id then
				correct_token = true
				break
			end
		end

		if correct_token and operation ~= nil then
			operation(root, file)
		end

		for _, token in ipairs(root.children) do
			recurse(token, token_ids, operation, on_exit, file)
		end

		if correct_token and on_exit ~= nil then
			on_exit(root, file)
		end
	end

	local function recurse2(root, config, file)
		if file == nil then file = root_file end
		if root.filename then file = root.filename end

		local enter_methods = config.enter[root.id]
		if enter_methods then
			for i = 1, #enter_methods do
				enter_methods[i](root, file)
				if ERRORED then return end
			end
		end

		if root.children then
			for _, token in ipairs(root.children) do
				recurse2(token, config, file)
				if ERRORED then return end
			end
		end

		local exit_methods = config.exit[root.id]
		if exit_methods then
			for i = 1, #exit_methods do
				exit_methods[i](root, file)
				if ERRORED then return end
			end
		end
	end

	--Fill in missing node data, just to make sure all nodes behave the same
	local function autofill(node)
		if not node.text then node.text = '' end
		if not node.children then
			node.children = {}
		else
			for i = 1, #node.children do
				autofill(node.children[i])
			end
		end
	end
	autofill(root)

	--Make sure subroutines and file imports are top-level statements
	--[[minify-delete]]
	local found_import = false
	local function check_top_level_stmts()
		found_import = false
		--[[/minify-delete]]

		local tok_level = 0
		recurse(root,
			{ TOK.subroutine, --[[minify-delete]] TOK.import_stmt, --[[/minify-delete]] TOK.if_stmt, TOK.for_stmt, TOK
				.kv_for_stmt, TOK.while_stmt }, function(token, file)
				--[[minify-delete]]
				if token.id == TOK.import_stmt then
					found_import = true
				end
				--[[/minify-delete]]

				--Enter scope
				if tok_level > 0 then
					if token.id == TOK.subroutine then
						parse_error(token.span, 'Subroutines cannot be defined inside other structures', file)
						--[[minify-delete]]
					elseif token.id == TOK.import_stmt then
						parse_error(token.span, 'Statement `' .. token.text .. '` cannot be inside other structures',
							file)
						--[[/minify-delete]]
					end
				end

				if token.text:sub(1, 1) == '?' then
					parse_error(token.span, 'Subroutine name cannot begin with `?`', file)
				end

				tok_level = tok_level + 1
			end, function(token, file)
				--Exit scope
				tok_level = tok_level - 1
			end)
		--[[minify-delete]]
	end
	check_top_level_stmts()
	--[[/minify-delete]]

	--Enforce top level stmts and import files.
	--Have to repeatedly do this until all dependencies are accounted for
	--[[minify-delete]]
	local imported_files = {} --Keep track of imported files, make sure there are no circular dependencies
	local function import_file(node)
		local new_asts = {}
		for i = 1, #node.value do
			local filename = node.value[i]
			local fp = io.open(filename, 'r')
			local text = nil
			if fp then text = fp:read('*all') end
			if text == nil then
				parse_error(node.span, 'COMPILER BUG: Imported file "' .. filename .. '" exists but also doesn\'t exist?',
					root_file)
				break
			end

			if imported_files[filename] then
				parse_error(node.children[i].span, 'File is already imported in ' .. imported_files[filename], root_file)
				break
			else
				imported_files[filename] = root_file

				local lexer, tokens = Lexer(text, filename), {}
				for t in lexer do table.insert(tokens, t) end --Iterate to get tokens.

				--Parse into AST and add to the list.
				local parser = SyntaxParser(tokens, filename)
				local ast = parser()

				if not ERRORED then
					recurse(ast, { TOK.import_stmt }, import_file)
					table.insert(new_asts, ast)
				end

				if ERRORED then
					parse_error(node.children[i].span, 'Error in included file', root_file)
				end
			end
		end

		if ERRORED then return end

		node.id = TOK.program
		node.children = new_asts
	end

	INFO.root_file = root_file

	recurse(root, { TOK.import_stmt }, import_file)

	check_top_level_stmts()
	--[[/minify-delete]]

	--[[PERFORM COMPILER PASSES]]

	local config = require "src.compiler.semantics.pass1"
	recurse2(root, config, root_file)
	local labels = config.finally()

	config = require "src.compiler.semantics.pass2"
	recurse2(root, config, root_file)
	local FUNCSIG = config.finally()

	--[[
		TYPE ANNOTATIONS
	]]
	local variables = {}
	local deduced_variable_types
	local current_sub = nil
	--[[minify-delete]]
	local in_cmd_eval = false
	--[[/minify-delete]]

	local function type_precheck(token, file)
		if token.id == TOK.subroutine then current_sub = token.text end
		if token.id == TOK.inline_command then in_cmd_eval = true end
	end

	local function type_checking(token, file)
		local signature

		--Unlike other tokens, "command" tokens only need the first child to be constant for us to deduce the type
		if token.id == TOK.inline_command or token.id == TOK.command then
			local ch = token.children[1]

			--subroutine eval is different
			if ch.id == TOK.gosub_stmt then
				if not token.type then
					local lbl = ch.children[1]
					if labels[lbl.text] then token.type = labels[lbl.text].return_type end
				end

				return
			end

			if token.id == TOK.inline_command then ch = ch.children[1] end

			--ignore "define" pseudo-command
			if ch.value == 'define' then return end

			if ch.value ~= nil and ch.id ~= TOK.lit_null and token.id == TOK.command then
				if not ALLOWED_COMMANDS[ch.value] and not BUILTIN_COMMANDS[ch.value] then
					--[[minify-delete]]

					--Tell user about incorrect stdout+err capture
					if ch.value == '!?' then
						parse_error(ch.span, 'Unknown shell command "!?" (you probably meant "?!")', file)
					end

					if _G['COERCE_SHELL_CMDS'] and not _G['RESTRICT_TO_PLASMA_BUILD'] then
						--If bash extension is enabled, try to run a shell command
						local bashcmd = '='
						if in_cmd_eval then bashcmd = '?' end

						table.insert(token.children, 1, {
							id = TOK.string,
							span = ch.span,
							text = bashcmd,
							value = bashcmd,
							type = _G['TYPE_STRING'],
						})
					else
						--[[/minify-delete]]

						--If command doesn't exist, try to help user by guessing the closest match (but still throw an error)
						local msg = 'Unknown command "' .. std.str(ch.value) .. '"'
						local guess = closest_word(std.str(ch.value), ALLOWED_COMMANDS, 4)
						if guess == nil or guess == '' then
							guess = closest_word(std.str(ch.value), BUILTIN_COMMANDS, 4)
						end

						if guess ~= nil and guess ~= '' then
							msg = msg .. ' (did you mean "' .. std.str(guess) .. '"?)'
						end
						parse_error(token.span, msg, file)

						--[[minify-delete]]
					end
					--[[/minify-delete]]
				end

				--[[minify-delete]]
				in_cmd_eval = false
				--[[/minify-delete]]

				if ALLOWED_COMMANDS[ch.value] then
					token.type = ALLOWED_COMMANDS[ch.value]
				else
					token.type = BUILTIN_COMMANDS[ch.value]
				end
			end

			if token.id == TOK.inline_command then token.type = token.children[1].type end
			return
		end

		if token.id == TOK.return_stmt then
			local sub = labels[current_sub]
			if sub then
				local exp_type = nil

				if not token.children or #token.children == 0 then
					exp_type = _G['TYPE_NULL']
				elseif token.children[1].type then
					exp_type = token.children[1].type
				end

				if sub.type and exp_type and not SIMILAR_TYPE(exp_type, sub.type) then
					sub.type = _G['TYPE_ANY']
				else
					sub.type = exp_type
				end
			end
			return
		end

		if token.id == TOK.subroutine then
			current_sub = nil
			return
		end

		if token.value ~= nil or token.id == TOK.lit_null then
			token.type = SIGNATURE(std.deep_type(token.value))
			return
		elseif token.id == TOK.index then
			local c2 = token.children[2]
			if c2.id == TOK.array_slice and #c2.children == 1 then
				c2.unterminated = true
			end

			local t1, t2 = token.children[1].type, token.children[2].type
			if t1 and t2 then
				if not SIMILAR_TYPE(t1, _G['TYPE_INDEXABLE']) then
					parse_error(token.children[1].span,
						'Cannot index a value of type `' ..
						TYPE_TEXT(t1) .. '`. Type must be `string`, `array`, or `object`', file)
					return
				end

				if SIMILAR_TYPE(t1, _G['TYPE_OBJECT']) then
					token.type = _G['TYPE_ANY']
				else
					if not SIMILAR_TYPE(t2, _G['TYPE_INDEXER']) then
						parse_error(token.children[1].span,
							'Cannot index with a value of type `' ..
							TYPE_TEXT(t2) .. '`. Must be `array[number]` or `number`', file)
						return
					end

					if SIMILAR_TYPE(t1, _G['TYPE_STRING']) then
						token.type = _G['TYPE_STRING']
					elseif EXACT_TYPE(t2, _G['TYPE_ANY']) then
						--If index is "any", result is either the same type as t1, or the subtype of t1
						token.type = MERGE_TYPES(t1, GET_SUBTYPES(t1))
					elseif SIMILAR_TYPE(t2, _G['TYPE_ARRAY']) then
						token.type = t1
					elseif HAS_SUBTYPES(t1) then
						token.type = GET_SUBTYPES(t1)
					else
						--We don't know what type of array this is, so result of non-const array index has to be "any"
						token.type = _G['TYPE_ANY']
					end
				end
			end
			return
		elseif token.id == TOK.variable then
			return
		elseif TYPESIG[token.id] ~= nil then
			signature = TYPESIG[token.id]
		elseif TYPESIG[token.text] ~= nil then
			signature = TYPESIG[token.text]
			--[[minify-delete]]
			if _G['RESTRICT_TO_PLASMA_BUILD'] and signature.plasma == false then
				parse_error(token.span, 'The `' .. token.text .. '` function cannot be used in the Plasma build.', file)
			end
			--[[/minify-delete]]
		else
			return
		end

		if #token.children > 0 then
			local found_correct_types = false

			if signature.valid then
				--Check that type signature of the params match up with the list of accepted types.
				for g = 1, #signature.valid do
					local found_match = true
					for i = 1, #token.children do
						local tp = token.children[i].type
						if tp then
							local s = signature.valid[g]
							if not SIMILAR_TYPE(tp, s[(i - 1) % #s + 1]) then found_match = false end
						end
					end
					if found_match then
						found_correct_types = true
						break
					end
				end

				if not found_correct_types then
					local options, got_types = {}, {}

					for i = 1, #signature.valid do
						table.insert(options, std.join(signature.valid[i], ',', TYPE_TEXT))
					end

					for i = 1, #token.children do
						table.insert(got_types, TYPE_TEXT(token.children[i].type or _G['TYPE_ANY']))
					end

					local msg
					if BUILTIN_FUNCS[token.text] then
						msg = 'Function "' .. token.text .. '(' .. FUNCSIG(token.text) .. ')"'
					else
						msg = 'Operator "' .. token.text .. '"'
					end
					parse_error(token.span,
						msg .. ' expected (' .. std.join(options, ' or ') .. ') but got (' ..
						std.join(got_types, ',') .. ')', file)
				end
			end

			if type(signature.out) == 'number' then
				--Return type matches that of the nth param
				token.type = token.children[signature.out].type
			else
				token.type = signature.out
			end
		else
			token.type = signature.out
		end
	end

	local function push_var(var, value)
		if not variables[var] then variables[var] = {} end
		table.insert(variables[var], {
			text = value,
			line = var.span.from.line,
			col = var.span.from.col,
		})
	end

	local function set_var(var, value)
		if not variables[var.text] then variables[var.text] = {} end
		variables[var.text][#variables[var.text]] = {
			text = value,
			line = var.span.from.line,
			col = var.span.from.col,
		}
	end

	local function variable_assignment(token)
		if token.id == TOK.for_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if not var.type then
				--Expression to iterate over is constant
				if ch.value ~= nil or ch.id == TOK.lit_null then
					local tp

					if type(ch.value) == 'table' then
						for _, val in pairs(ch.value) do
							local _tp = SIGNATURE(std.deep_type(val))
							if tp == nil then
								tp = _tp
							elseif tp ~= _tp then
								--Type will change, so it can't be reduced to a constant state.
								--Maybe change this later?
								tp = nil
								break
							end
						end
					else
						tp = SIGNATURE(std.deep_type(ch.value))
					end

					--If loop variable has a consistent type, then we know for sure what it will be.
					if tp ~= nil then
						push_var(var, tp)
						var.type = tp
						deduced_variable_types = true
					end
				end
			end
		elseif token.id == TOK.try_stmt then
			if token.children[3] then
				push_var(token.children[3], _G['TYPE_OBJECT'])
			end
		end
	end

	local function variable_unassignment(token)
		if token.id == TOK.for_stmt then
			local var = token.children[1].text
			local ch = token.children[2]
			if variables[var] then
				if #variables[var] == 1 then
					variables[var] = nil
				else
					table.remove(variables)
				end
			end

			if ch.type and HAS_SUBTYPES(ch.type) then
				token.children[1].type = GET_SUBTYPES(ch.type)
			end
		elseif token.id == TOK.kv_for_stmt then
			local key, value, expr = token.children[1], token.children[2], token.children[3]

			for _, i in ipairs({ key.text, value.text }) do
				if variables[i] then
					if #variables[i] == 1 then
						variables[i] = nil
					else
						table.remove(variables)
					end
				end
			end

			if not key.type then
				local found_pairs = false
				while expr do
					if found_pairs then
						if expr.type then
							value.type = expr.type.subtype
							if expr.type.type == 'object' then
								key.type = _G['TYPE_STRING']
							elseif expr.type.type == 'array' then
								key.type = _G['TYPE_NUMBER']
							end
						end
						break
					end

					if expr.id ~= TOK.func_call or (expr.text ~= 'pairs' and expr.text ~= 'reverse' and expr.text ~= 'sort') then
						break
					end

					if expr.text == 'pairs' then found_pairs = true end

					expr = expr.children[1]
				end
			end
		elseif token.id == TOK.let_stmt then
			local var = token.children[1]
			local ch = token.children[2]

			if var.type then return end

			if #token.children > 2 then
				--Don't deduce types for let statements that are updating variables.
				--Those don't define what the variable's actual type is.
				return
			end

			local tp = nil
			if ch and ch.type then tp = ch.type end

			if #var.children > 0 then
				local vars = { var.text }
				for i = 1, #var.children do
					table.insert(vars, var.children[i].text)
				end

				for i = 1, #vars do
					tp = nil
					if ch then
						if ch.id == TOK.array_concat then
							if ch.children[i] and ch.children[i].type then
								tp = ch.children[i].type
							end
						elseif ch.value or ch.id == TOK.lit_null then
							if ch.id == TOK.lit_array then
								tp = SIGNATURE(std.deep_type(ch.value[i]))
							elseif i == 1 then
								tp = SIGNATURE(std.deep_type(ch.value))
							else
								tp = _G['TYPE_NULL']
							end
						else
							tp = _G['TYPE_ANY']
						end
					else
						tp = _G['TYPE_NULL']
					end

					if tp ~= nil then
						local child = var
						if i > 1 then child = var.children[i - 1] end
						set_var(child, tp)
						child.type = tp
						deduced_variable_types = true
					end
				end
			elseif tp ~= nil then
				set_var(var, tp)
				var.type = tp
				deduced_variable_types = true
			end
		elseif token.id == TOK.variable then
			if token.type then return end

			local tp = variables[token.text]
			if tp then
				local tp1 = tp[#tp]
				if tp1.line > token.span.from.line or (tp1.line == token.span.from.line and tp1.col > token.span.from.col) then
					if #tp < 2 then return end
					token.type = tp[#tp - 1].text
				else
					token.type = tp[#tp].text
				end
			elseif token.text == '$' then
				token.type = _G['TYPE_ARRAY_STRING']
			elseif token.text == '@' then
				token.type = _G['TYPE_ARRAY']
			elseif token.text == '_VARS' then
				token.type = _G['TYPE_OBJECT']
			elseif token.text == '_VERSION' then
				token.type = _G['TYPE_STRING']
			elseif token.text == '_ENV' then
				token.type = _G['TYPE_ENV']
			end
		end
	end

	--Check what variables are never assigned or never referenced
	local assigned_vars = {
		['$'] = {},
		['@'] = {},
		['_VARS'] = {},
		['_VERSION'] = {},
		['_ENV'] = {},
	}
	local readonly_vars = {
		['_VARS'] = true,
		['_VERSION'] = true,
		['_ENV'] = true,
	}

	local this_var = nil
	recurse(root, { TOK.var_assign, TOK.inline_command, TOK.try_stmt }, function(token, file)
		local ix = token.span.from
		if token.id == TOK.var_assign then
			this_var = token.text
			token.ignore = true --If this variable is not used anywhere, we can optimize it away.

			--Don't allow assignment to read-only variables.
			if readonly_vars[this_var] then
				parse_error(token.span, this_var .. ' variable is read-only', file)
			end

			--If we're specifically keeping the vars, then don't remove the dead code.
			---@diagnostic disable-next-line
			if V7 then token.ignore = false end

			if not assigned_vars[this_var] then assigned_vars[this_var] = {} end
			assigned_vars[this_var][ix.line .. '|' .. ix.col] = token
		elseif token.id == TOK.try_stmt then
			local var = token.children[3]
			if var then
				if not assigned_vars[var.text] then assigned_vars[var.text] = {} end
				assigned_vars[var.text][ix.line .. '|' .. ix.col] = var
			end
		elseif this_var then
			local cmd = nil
			if token.children[1].id == TOK.command then cmd = token.children[1].children[1].text end
			--If the command has no side-effects, we CAN still optimize them away.
			if cmd ~= 'time' and cmd ~= 'systime' and cmd ~= 'sysdate' then
				--We CAN'T fully optimize this variable away because it has a command eval in it.
				for _, var_decl in pairs(assigned_vars[this_var]) do var_decl.ignore = false end
			end
		end
	end, function(token, file)
		if token.id == TOK.var_assign or token.id == TOK.try_stmt then this_var = nil end
	end)
	recurse(root, { TOK.variable, TOK.list_comp }, function(token, file)
		if token.id == TOK.list_comp then
			local child = token.children[2]
			local ix = child.span.from
			if not assigned_vars[child.text] then assigned_vars[child.text] = {} end
			assigned_vars[child.text][ix.line .. '|' .. ix.col] = child
			return
		end

		if assigned_vars[token.text] then
			for _, var_decl in pairs(assigned_vars[token.text]) do var_decl.is_referenced = true end
		else
			--[[minify-delete]]
			if _G['LANGUAGE_SERVER'] then
				INFO.warning(token.span, 'Variable is never declared', file)
			end
			--[[/minify-delete]]
			--Using a variable that is never declared.
			token.ignore = true
		end
	end, function(token, file)
		if token.id == TOK.list_comp then
			local child = token.children[2]
			local ix = child.span.from

			assigned_vars[child.text][ix.line .. '|' .. ix.col] = nil
			if next(assigned_vars[child.text]) == nil then assigned_vars[child.text] = nil end
		end
	end)
	--[[minify-delete]]
	--TODO: MAKE SURE CORRECT FILE!!!
	if _G['LANGUAGE_SERVER'] then
		for _, decls in pairs(assigned_vars) do
			for _, var_decl in pairs(decls) do
				if not var_decl.is_referenced and not _G['EXPORT_LINES'][var_decl.span.from.line] then
					local filename = root_file
					if var_decl.filename then filename = var_decl.filename end
					if var_decl.text:sub(1, 1) ~= '_' then
						INFO.warning(var_decl.span,
							'Variable is never used. To indicate that this is intentional, prefix with an underscore',
							filename)
					end
					INFO.dead_code(var_decl.span, '', filename)
				end
			end
		end
	end
	--[[/minify-delete]]

	--[[
		CONSTANT FOLDING AND TYPE DEDUCTIONS
	]]
	deduced_variable_types = true
	while deduced_variable_types do
		deduced_variable_types = false

		--First pass at deducing all types
		recurse(root,
			{ TOK.string_open, TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.index, TOK.array_concat, TOK
				.array_slice, TOK.comparison, TOK.negate, TOK.func_call, TOK.concat, TOK.length, TOK.lit_array, TOK
				.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.inline_command, TOK.command, TOK.return_stmt, TOK
				.subroutine }, type_precheck, type_checking)

		--Fold constants. this improves performance at runtime, and checks for type errors early on.
		if not ERRORED then
			recurse(root,
				{ TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.length, TOK.func_call, TOK.array_concat, TOK
					.negate, TOK.comparison, TOK.concat, TOK.array_slice, TOK.string_open, TOK.index, TOK.ternary, TOK
					.list_comp, TOK.object, TOK.key_value_pair }, nil, FOLD_CONSTANTS)
		end

		--Set any variables we can
		if not ERRORED then
			recurse(root, { TOK.for_stmt, TOK.kv_for_stmt, TOK.let_stmt, TOK.variable, TOK.try_stmt },
				variable_assignment, variable_unassignment)
		end

		if ERRORED then break end
	end

	if not ERRORED then
		--One last pass at deducing all types (after any constant folding)
		recurse(root,
			{ TOK.string_open, TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.index, TOK.array_concat, TOK
				.array_slice, TOK.comparison, TOK.negate, TOK.func_call, TOK.concat, TOK.length, TOK.lit_array, TOK
				.lit_boolean, TOK.lit_null, TOK.lit_number, TOK.variable, TOK.inline_command, TOK.command, TOK
				.return_stmt, TOK.subroutine, TOK.length }, nil, type_checking)
	end

	-- After type checking, run one more pass on the AST to adjust synonym functions and so on.
	config = require "src.compiler.semantics.pass3"
	recurse2(root, config, root_file)

	--If running as language server, print type info for any variable declarations or command calls.
	--[[minify-delete]]
	if _G['LANGUAGE_SERVER'] then
		recurse(root, { TOK.let_stmt, TOK.for_stmt, TOK.kv_for_stmt, TOK.inline_command, TOK.command, TOK.subroutine },
			function(token, file)
				local var = token.children[1]
				if token.id == TOK.inline_command or token.id == TOK.command then
					local cmd = var
					if token.id == TOK.inline_command then cmd = cmd.children[1] end

					if cmd.value then
						if var.id == TOK.gosub_stmt then
							if labels[cmd.text] then
								INFO.hint(cmd.span,
									'Subroutine `' ..
									cmd.text ..
									'` defined on line ' ..
									labels[cmd.text].span.from.line .. ', col ' .. labels[cmd.text].span.from.col, file)
								local tp = labels[cmd.text].type
								if EXACT_TYPE(tp, TYPE_NULL) then
									INFO.info(cmd.span,
										'Subroutine `' ..
										cmd.text ..
										'` always returns null, so using an inline command eval here is not helpful',
										file)
								elseif tp then
									INFO.hint(cmd.span, 'returns: ' .. TYPE_TEXT(tp), file)
								end
							end
						else
							local tp
							if ALLOWED_COMMANDS[cmd.value] then
								tp = ALLOWED_COMMANDS[cmd.value]
							else
								tp = BUILTIN_COMMANDS[cmd.value]
							end

							if token.id == TOK.command and tp then
								INFO.hint(cmd.span, _G['CMD_DESCRIPTION'][cmd.text], file)
								---@diagnostic disable-next-line
								INFO.hint(cmd.span, 'returns: ' .. TYPE_TEXT(tp), file)
							end

							if token.id == TOK.inline_command and EXACT_TYPE(tp, TYPE_NULL) then
								INFO.info(cmd.span,
									'Command `' ..
									cmd.text ..
									'` always returns null, so using an inline command eval here is not helpful', file)
							end
						end
					end
				elseif token.id == TOK.subroutine then
					if token.type then INFO.hint(token.span, 'returns: ' .. TYPE_TEXT(token.type), file) end
				elseif token.id == TOK.kv_for_stmt then
					if var.type then INFO.hint(var.span, 'type: ' .. TYPE_TEXT(var.type), file) end
					var = token.children[2]
					if var.type then INFO.hint(var.span, 'type: ' .. TYPE_TEXT(var.type), file) end
				else
					--Variable declarations
					if var.type then INFO.hint(var.span, 'type: ' .. TYPE_TEXT(var.type), file) end
					for _, kid in ipairs(var.children) do
						if kid.type then INFO.hint(kid.span, 'type: ' .. TYPE_TEXT(kid.type), file) end
					end
				end
			end)
	end
	--[[/minify-delete]]

	--Restructure match statements into an equivalent if/elif/else block.
	recurse(root, { TOK.match_stmt }, function(token, file)
		local iter = { token.children[2] }
		if iter[1].id == TOK.program then iter = iter[1].children end

		if iter == nil then
			parse_error(token.span, 'COMPILER BUG: Match statement has no comparison branches!', file)
			return
		end

		local constant = token.children[1].value ~= nil or token.children[1].id == TOK.lit_null

		token.id = TOK.program
		local var = LABEL_ID()

		---@type Token
		local condition = {
			id = TOK.let_stmt,
			text = 'let',
			span = token.span,
			children = {
				{
					id = TOK.var_assign,
					text = var,
					span = token.span,
				},
				token.children[1],
			}
		}

		local else_branch = token.children[3]
		for i = #iter, 1, -1 do
			iter[i].children[3] = else_branch
			else_branch = iter[i]

			--Optimization: allow branch pruning if the
			local compare_node = token.children[1]
			if not constant then
				compare_node = {
					id = TOK.variable,
					text = var,
					span = else_branch.children[1].span,
				}
			end

			local else_node = else_branch.children[1]
			if else_node.id == TOK.comparison and #else_node.children < 2 then
				--Handle special fuzzy match syntax like "if {> expr} then ... end", etc.
				table.insert(else_node.children, 1, compare_node)
			else
				--Default behavior is to insert "=" operator.
				else_branch.children[1] = {
					id = TOK.comparison,
					text = '=',
					span = else_node.span,
					children = {
						compare_node,
						else_node,
					},
				}
			end
		end

		if constant then
			token.children = { else_branch }

			--If branch condition is constant, try to fold constants one more time.
			--This improves performance at runtime, and can allow branches to be pruned at compile time.
			if not ERRORED then
				recurse(root,
					{ TOK.add, TOK.multiply, TOK.exponent, TOK.boolean, TOK.length, TOK.func_call, TOK.array_concat, TOK
						.negate, TOK.comparison, TOK.concat, TOK.array_slice, TOK.string_open, TOK.index, TOK.ternary,
						TOK.list_comp, TOK.object, TOK.key_value_pair }, nil, FOLD_CONSTANTS)
			end
		else
			token.children = { condition, else_branch }
		end
	end)

	--Check if subroutines are even used
	--We also keep track of what subroutines each subroutine references.
	--This lets us remove recursive subroutines, or subs that reference each other
	local sub_refs = {}
	local top_level_subs = {}
	local current_sub = nil
	recurse(root, { TOK.gosub_stmt, TOK.subroutine }, function(token, file)
		if token.id == TOK.gosub_stmt then
			local text = token.children[1].value or token.children[1].text

			if current_sub then
				if not sub_refs[current_sub] then sub_refs[current_sub] = {} end
				table.insert(sub_refs[current_sub], text)
			else
				local sub = labels[text]
				if sub then sub.is_referenced = true end
				top_level_subs[text] = true
			end
		else
			current_sub = token.text
		end
	end, function(token, file)
		if token.id == TOK.subroutine then current_sub = nil end
	end)

	--Scan through subroutines and check if we can trace gosubs from the top level down to each subroutine.
	--If we can, then we CANNOT optimize the subroutine away.
	local function trace_subs(parent, children, top_parent)
		for _, child in ipairs(children) do
			if child ~= parent and child ~= top_parent then
				local sub = labels[child]
				if sub then sub.is_referenced = true end
				if sub_refs[child] then trace_subs(child, sub_refs[child], top_parent) end
			end
		end
	end
	for label, _ in pairs(top_level_subs) do
		if sub_refs[label] then trace_subs(label, sub_refs[label], label) end
	end

	--Check gosub uses. Gosub IS allowed to have a single, constant value as its parameter.
	recurse(root, { TOK.gosub_stmt }, function(token, file)
		local label
		if token.children[1].value ~= nil or token.children[1].id == TOK.lit_null then
			label = std.str(token.children[1].value)
		elseif token.children[1].id == TOK.text then
			label = token.children[1].text
		end

		if label == nil then
			local kid = token.children[1]

			--Check if the dynamic gosub could never possibly hit certain subroutines
			---@type table|nil
			local begins, ends, contains = nil, nil, {}
			if kid and kid.children[1] then
				begins = kid.children[1]
				ends = kid.children[#kid.children]
				for i = 2, #kid.children - 1 do
					if kid.children[i].value ~= nil then
						table.insert(contains, std.str(kid.children[i].value))
					end
				end
			end

			if begins and (begins.value ~= nil or begins.id == TOK.lit_null) then begins = { value = begins.text } end
			if ends and (ends.value ~= nil or ends.id == TOK.lit_null) then ends = { value = ends.text } end

			--If we have a dynamic gosub then we can't remove any subroutines, as we don't really know what subroutine is referenced.
			for k, i in pairs(labels) do
				local begins_with = begins and k:sub(1, #std.str(begins.value)) == begins.value
				local ends_with = ends and k:sub(#k - #std.str(ends.value) + 1, #k) == ends.value
				local does_contain = #contains == 0 and (not begins or not begins.value) and
					(not ends or not ends.value) --If there are no const parts, then we can't know.

				for j = 1, #contains do
					if std.contains(k, contains[j]) then does_contain = true end
				end

				if begins_with or ends_with or does_contain then
					i.is_referenced = true
				end
			end
			return
		end

		if labels[label] == nil then
			local msg = 'Subroutine `' .. label .. '` not declared anywhere'
			local guess = closest_word(label, labels, 4)
			if guess ~= nil and guess ~= '' then
				msg = msg .. ' (did you mean "' .. guess .. '"?)'
			end
			parse_error(token.children[1].span, msg, file)
		else
			token.ignore = labels[label].ignore
		end
	end)

	--Warn if subroutines are not used.
	--[[minify-delete]]
	if _G['LANGUAGE_SERVER'] then
		recurse(root, { TOK.subroutine }, function(token, file)
			if not token.is_referenced and not _G['EXPORT_LINES'][token.span.from.line] then
				local span = {
					from = token.span.from,
					to = {
						line = token.span.to.line,
						col = token.span.to.col - 4,
					}
				}

				INFO.dead_code(span, 'Subroutine `' .. token.text .. '` is never used.', file)
			end
		end)
	end
	--[[/minify-delete]]

	--If using the PC build, make sure shell pipe operators do not get escaped.
	--[[minify-delete]]
	if not _G['RESTRICT_TO_PLASMA_BUILD'] then
		recurse(root, { TOK.command }, function(token, file)
			for i = 1, #token.children do
				local c = token.children[i]
				if c.id == TOK.text and c.text:match('[|<>]') then
					c.id = TOK.raw_sh_text
					c.text = _G['RAW_SH_TEXT_SENTINEL'] .. c.text:gsub('%!', '2'):gsub('%?', '1')
					c.value = c.text
				end
			end
		end)
	end
	--[[/minify-delete]]

	--Lastly perform any extra optimizations, now that the code is fully validated.

	--[[REMOVE DEAD CODE]]
	config = require "src.compiler.semantics.dead_code"
	recurse2(root, config, root_file)
	config.finally()


	--[[EXIT]]
	if ERRORED then terminate() end
	return root
end
