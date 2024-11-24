--Generate an empty matrix
local function matrix(row --[[number]], col --[[number]])
	local m = {}
	for i = 1, row do
		m[i] = {}
		for j = 1, col do
			m[i][j] = 0
		end
	end
	return m
end

--Levenstein distance, for finding how similar one string is to another
function lev(a --[[string]], b --[[string]])
	local M = matrix(#a + 1, #b + 1)
	local i, j, cost
	local row, col = #M, #M[1]

	for i = 1, row do
		M[i][1] = i - 1
	end
	for j = 1, col do
		M[1][j] = j - 1
	end

	for i = 2, row do
		for j = 2, col do
			if (a:sub(i - 1, i - 1) == b:sub(j - 1, j - 1)) then
				cost = 0
			else
				cost = 1
			end
			M[i][j] = math.min(math.min(M[i - 1][j] + 1, M[i][j - 1] + 1), M[i - 1][j - 1] + cost)
		end
	end

	return M[row][col]
end

function closest_word(this_word --[[string]], word_list --[[table]], threshold --[[number]])
	local cDist = -1
	local cWord = ""

	--First, check if this_word is the start of an item in the word_list
	local score = 0
	for value, _ in pairs(word_list) do
		if value:sub(1, #this_word) == this_word then
			local new_score = #this_word - #value - 1
			if new_score < score then
				score = new_score
				cWord = value
			end
		end
	end
	if score < 0 then return cWord end

	--Then, check if this_word is the end of an item in the word_list
	for value, _ in pairs(word_list) do
		if value:sub(#value - #this_word + 1, #value) == this_word then
			local new_score = #this_word - #value - 1
			if new_score < score then
				score = new_score
				cWord = value
			end
		end
	end
	if score < 0 then return cWord end

	--If no good match, check levenshtein distance
	for value, _ in pairs(word_list) do
		local levRes = lev(this_word, value)
		if levRes < cDist or cDist == -1 then
			cDist = levRes
			cWord = value
		end
	end

	if cDist <= threshold then
		return cWord
	else
		return nil --No good or even close match
	end
end
