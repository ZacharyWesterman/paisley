--[[
  Author: OGabrieLima
  GitHub: https://github.com/OGabrieLima
  Source: https://github.com/OGabrieLima/lua-sha256
  Discord: ogabrielima
  Description: This is a Lua script that implements the SHA-256 algorithm to calculate the hash of a message.
               It includes a helper function for right rotation (bitwise) and the main function `sha256`.
               The `sha256` function can be used to calculate the SHA-256 hash of a message.
  Creation Date: 2024-04-08
]]

---Binary integer shift right
---@param val_in integer
---@param count integer
---@return integer
local function rshift(val_in, count)
	for i = 1, count do
		val_in = math.floor(val_in / 2)
	end
	return val_in
end

---Binary integer shift right
---@param val_in integer
---@param count integer
---@return integer
local function lshift(val_in, count)
	for i = 1, count do
		val_in = val_in * 2
	end
	return val_in
end

---Perform bitwise operations on integers
---@param a integer
---@param b integer
---@param operator function
---@return integer
local function boolean(a, b, operator)
	local result = 0
	for i = 1, 32 do
		local pt = 2 ^ (32 - i)
		local b1 = math.floor(a / pt) % 2
		local b2 = math.floor(b / pt) % 2
		result = result * 2
		if operator(b1, b2) then
			result = result + 1
		end
	end
	return result
end

---Bitwise OR
---@param a integer
---@param b integer
---@return integer
local function bitor(a, b)
	return boolean(a, b, function(b1, b2)
		return b1 == 1 or b2 == 1
	end)
end

---Bitwise AND
---@param a integer
---@param b integer
---@return integer
local function bitand(a, b)
	return boolean(a, b, function(b1, b2)
		return b1 == 1 and b2 == 1
	end)
end

---Bitwise NOT
---@param a integer
---@return integer
local function bitnot(a)
	return boolean(a, 0, function(b1, b2)
		return b1 == 0
	end)
end

---Bitwise XOR
---@param a integer
---@param b integer
---@return integer
local function bitxor(a, b)
	return boolean(a, b, function(b1, b2)
		return (b1 == 1 or b2 == 1) and (b1 ~= b2)
	end)
end

---Binary integer rotate right
---@param x integer The number to rotate
---@param y integer The number of bits to rotate
---@return integer result The rotated number
local function bit_ror(x, y)
	return bitand(bitor(rshift(x, y), lshift(x, (32 - y))), 0xFFFFFFFF)
end

---Calculate the SHA256 hash of a string
---@param message string The message to hash
---@return string hash The SHA256 hash of the message
function SHA256(message)
	local k = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
	}

	local function preprocess(message)
		local len = #message
		local bitLen = len * 8
		message = message .. "\128" -- append single '1' bit

		local zeroPad = 64 - ((len + 9) % 64)
		if zeroPad ~= 64 then
			message = message .. string.rep("\0", zeroPad)
		end

		-- append length
		message = message .. string.char(
			bitand(rshift(bitLen, 56), 0xFF),
			bitand(rshift(bitLen, 48), 0xFF),
			bitand(rshift(bitLen, 40), 0xFF),
			bitand(rshift(bitLen, 32), 0xFF),
			bitand(rshift(bitLen, 24), 0xFF),
			bitand(rshift(bitLen, 16), 0xFF),
			bitand(rshift(bitLen, 8), 0xFF),
			bitand(bitLen, 0xFF)
		)

		return message
	end

	local function chunkify(message)
		local chunks = {}
		for i = 1, #message, 64 do
			table.insert(chunks, message:sub(i, i + 63))
		end
		return chunks
	end

	local function processChunk(chunk, hash)
		local w = {}

		for i = 1, 64 do
			if i <= 16 then
				w[i] = bitor(
					lshift(string.byte(chunk, (i - 1) * 4 + 1), 24),
					bitor(
						lshift(string.byte(chunk, (i - 1) * 4 + 2), 16),
						bitor(
							lshift(string.byte(chunk, (i - 1) * 4 + 3), 8),
							string.byte(chunk, (i - 1) * 4 + 4)
						)
					)
				)
			else
				local s0 = bitxor(bitxor(bit_ror(w[i - 15], 7), bit_ror(w[i - 15], 18)), rshift(w[i - 15], 3))
				local s1 = bitxor(bitxor(bit_ror(w[i - 2], 17), bit_ror(w[i - 2], 19)), rshift(w[i - 2], 10))
				w[i] = bitand(w[i - 16] + s0 + w[i - 7] + s1, 0xFFFFFFFF)
			end
		end

		local a, b, c, d, e, f, g, h = table.unpack(hash)

		for i = 1, 64 do
			local s1 = bitxor(bitxor(bit_ror(e, 6), bit_ror(e, 11)), bit_ror(e, 25))
			local ch = bitxor(bitand(e, f), bitand(bitnot(e), g))
			local temp1 = bitand(h + s1 + ch + k[i] + w[i], 0xFFFFFFFF)
			local s0 = bitxor(bitxor(bit_ror(a, 2), bit_ror(a, 13)), bit_ror(a, 22))
			local maj = bitxor(bitxor(bitand(a, b), bitand(a, c)), bitand(b, c))
			local temp2 = bitand(s0 + maj, 0xFFFFFFFF)

			h = g
			g = f
			f = e
			e = bitand(d + temp1, 0xFFFFFFFF)
			d = c
			c = b
			b = a
			a = bitand(temp1 + temp2, 0xFFFFFFFF)
		end

		return bitand(hash[1] + a, 0xFFFFFFFF),
			bitand(hash[2] + b, 0xFFFFFFFF),
			bitand(hash[3] + c, 0xFFFFFFFF),
			bitand(hash[4] + d, 0xFFFFFFFF),
			bitand(hash[5] + e, 0xFFFFFFFF),
			bitand(hash[6] + f, 0xFFFFFFFF),
			bitand(hash[7] + g, 0xFFFFFFFF),
			bitand(hash[8] + h, 0xFFFFFFFF)
	end

	message = preprocess(message)
	local chunks = chunkify(message)

	local hash = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 }
	for _, chunk in ipairs(chunks) do
		hash = { processChunk(chunk, hash) }
	end

	local result = ""
	for _, h in ipairs(hash) do
		result = result .. string.format("%08x", h)
	end

	return result
end
