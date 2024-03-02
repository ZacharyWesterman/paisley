---@class Span
---@field from {line:integer, col:integer}
---@field to {line:integer, col:integer}
Span = {}

---Create a new span from a range of indexes.
---@param begin_line integer
---@param begin_col integer
---@param end_line integer
---@param end_col integer
---@return Span
function Span:new(begin_line, begin_col, end_line, end_col)
	local span = {
		from = {
			line = begin_line,
			col = begin_col,
		},
		to = {
			line = end_line,
			col = end_col,
		}
	}

	return span
end

---Create a new span from two other spans.
---@param span1 Span
---@param span2 Span
---@return Span
function Span:merge(span1, span2)
	local span = {
		from = {
			line = span1.from.line,
			col = span1.from.col,
		},
		to = {
			line = span2.to.line,
			col = span2.to.col,
		},
	}

	return span
end
