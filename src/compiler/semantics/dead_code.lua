--Remove the body of conditionals that will never get executed
local function if_stmt_const(token, file)
	local cond = token.children[1]
	if cond.value ~= nil or cond.id == TOK.lit_null then
		--Decide whether to remove "then" or "else" branch
		local ix, id, text = 2, TOK.kwd_then, 'then'
		if std.bool(cond.value) then
			ix, id, text = 3, TOK.kwd_end, 'end'
		end

		--[[minify-delete]]
		if LANGUAGE_SERVER then
			if token.children[ix].id == TOK.kwd_end then return end
			INFO.dead_code(token.children[ix].span, '', file)
		end
		--[[/minify-delete]]

		--[[minify-delete]]
		if not KEEP_DEAD_CODE then --[[/minify-delete]]
			token.children[ix] = {
				id = id,
				span = token.children[ix].span,
				text = text,
				children = {},
			}
			--[[minify-delete]]
		end --[[/minify-delete]]
	end
end

return {
	enter = {
		[TOK.if_stmt] = {
			if_stmt_const,
		},

		[TOK.elif_stmt] = {
			if_stmt_const,
		},

		[TOK.kwd_end] = {
			function() return true end,
		},

		[TOK.while_stmt] = {
			--Remove the body of loops that will never get executed
			function(token, file)
				local cond = token.children[1]
				if (cond.value ~= nil or cond.id == TOK.lit_null) and not std.bool(cond.value) then
					--[[minify-delete]]
					if LANGUAGE_SERVER then
						INFO.dead_code(token.span, '', file)
					end
					--[[/minify-delete]]

					--[[minify-delete]]
					if not KEEP_DEAD_CODE then --[[/minify-delete]]
						token.children = { cond }
						--[[minify-delete]]
					end --[[/minify-delete]]
				end
			end,
		},

		[TOK.for_stmt] = {
			--Remove the body of loops that will never get executed
			function(token, file)
				local cond = token.children[2]
				if (cond.value ~= nil or cond.id == TOK.lit_null) and not std.bool(cond.value) then
					--[[minify-delete]]
					if LANGUAGE_SERVER then
						INFO.dead_code(token.span, '', file)
					end
					--[[/minify-delete]]

					--[[minify-delete]]
					if not KEEP_DEAD_CODE then --[[/minify-delete]]
						token.children = { token.children[1], cond }
						--[[minify-delete]]
					end --[[/minify-delete]]
				end
			end,
		},

		[TOK.kv_for_stmt] = {
			--Remove the body of loops that will never get executed
			function(token, file)
				local cond = token.children[3]
				if (cond.value ~= nil or cond.id == TOK.lit_null) and not std.bool(cond.value) then
					--[[minify-delete]]
					if LANGUAGE_SERVER then
						INFO.dead_code(token.span, '', file)
					end
					--[[/minify-delete]]

					--[[minify-delete]]
					if not KEEP_DEAD_CODE then --[[/minify-delete]]
						token.children = { token.children[1], token.children[2], cond }
						--[[minify-delete]]
					end --[[/minify-delete]]
				end
			end,
		},

		[TOK.program] = {
			--Remove dead code after stop, return, continue, or break statements
			function(token, file)
				local dead_code_span = nil

				for i = 1, #token.children do
					if dead_code_span then
						--[[minify-delete]]
						if not KEEP_DEAD_CODE then --[[/minify-delete]]
							token.children[i] = nil
							--[[minify-delete]]
						end --[[/minify-delete]]
					else
						local node = token.children[i]
						if node.id == TOK.kwd_stop or node.id == TOK.return_stmt or node.id == TOK.continue_stmt or node.id == TOK.break_stmt then
							--if this is not the last statement in the list,
							--then mark all future statements as dead code.
							if i < #token.children then
								dead_code_span = {
									from = token.children[i + 1].span.from,
									to = token.children[#token.children].span.to,
								}
							end
						end
					end
				end

				--[[minify-delete]]
				if LANGUAGE_SERVER and dead_code_span then
					--Warn about dead code
					INFO.dead_code(dead_code_span, 'Dead code', file)
				end
				--[[/minify-delete]]
			end,
		},
	},

	exit = {

	},

	finally = function() end,
}
