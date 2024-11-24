--[[ Sources:
	Hashing functions: https://github.com/JustAPerson/LuaCrypt/blob/master/sha2.lua
	Serializing funcs: https://github.com/JustAPerson/LuaCrypt/blob/master/libbit.lua
--]]

---Binary integer rotate right
---@param val_in integer
---@param count integer
---@return integer
local function ror(val_in, count)
	for i = 1, count do
		local rollover = (val_in % 2) * 0x80000000
		val_in = math.floor(val_in / 2) + rollover
	end
	return val_in
end

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

---Bitwise XOR
---@param a integer
---@param b integer
---@return integer
local function bxor(a, b)
	local function logical_xor(b1, b2)
		if (b1 == 1 or b2 == 1) and (b1 ~= b2) then return true else return false end
	end

	return boolean(a, b, logical_xor)
end

---Bitwise AND
---@param a integer
---@param b integer
---@return integer
local function band(a, b)
	local function logical_and(b1, b2)
		if b1 == 1 and b2 == 1 then return true else return false end
	end

	return boolean(a, b, logical_and)
end

---Bitwise NOT
---@param a integer
---@return integer
local function bnot(a)
	local function logical_not(b1, b2)
		if b1 == 0 then return true else return false end
	end

	return boolean(a, a, logical_not)
end

---Serialize integer to string
---@param in_val integer
---@return string
local function int32_str(in_val)
	local result = ""
	for i = 0, 3 do
		local mod = 256 ^ (3 - i)
		result = result .. string.char(math.floor(in_val / mod))
		in_val = in_val % mod
	end
	return result
end

---Unserialize integer from string
---@param in_val string
---@return integer
local function str_int32(in_val)
	local a, b, c, d = in_val:byte(1, 4)
	return a * 256 ^ 3 + b * 256 ^ 2 + c * 256 + d
end


local k256 = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

---Pad a string to the appropriate length needed for SHA256 blocks
---@param in_val string
---@return string
local function preprocess256(in_val)
	local length = #in_val
	local padding = (-length - 9) % 64
	return in_val .. "\128" .. ("\0"):rep(padding) .. "\0\0\0\0" .. int32_str(length * 8)
end

---@param in_val string The value to digest.
---@param iter integer The current iteration.
---@param H integer[] The current internal state.
local function digest_block256(in_val, iter, H)
	local s10
	local t1, t2
	local chmaj
	local word
	local a, b, c, d, e, f, g, h

	local limit = 2 ^ 32
	local W = {}
	local chunk = in_val:sub(iter, iter + 63)
	local c1 = 0

	for i = 1, 64, 4 do
		c1 = c1 + 1
		W[c1] = str_int32(chunk:sub(i, i + 3))
	end

	--Extend 16 words into 64
	for t = 17, 64 do
		word = W[t - 2]
		s10 = bxor(bxor(ror(word, 17), ror(word, 19)), rshift(word, 10))
		word = W[t - 15]
		chmaj = bxor(bxor(ror(word, 7), ror(word, 18)), rshift(word, 3))
		W[t] = s10 + W[t - 7] + chmaj + W[t - 16]
	end

	a, b, c, d = H[1], H[2], H[3], H[4]
	e, f, g, h = H[5], H[6], H[7], H[8]

	for t = 1, 64 do
		s10 = bxor(bxor(ror(e, 6), ror(e, 11)), ror(e, 25))
		chmaj = bxor(band(e, f), band(bnot(e), g))
		t1 = h + s10 + chmaj + k256[t] + W[t]
		s10 = bxor(bxor(ror(a, 2), ror(a, 13)), ror(a, 22))
		chmaj = bxor(bxor(band(a, b), band(a, c)), band(b, c))
		t2 = s10 + chmaj
		h = g
		g = f
		f = e
		e = d + t1
		d = c
		c = b
		b = a
		a = t1 + t2
	end

	H[1] = (a + H[1]) % limit
	H[2] = (b + H[2]) % limit
	H[3] = (c + H[3]) % limit
	H[4] = (d + H[4]) % limit
	H[5] = (e + H[5]) % limit
	H[6] = (f + H[6]) % limit
	H[7] = (g + H[7]) % limit
	H[8] = (h + H[8]) % limit
end

---Calculate the SHA256 hash of a string
---@param in_val string
---@return string
function SHA256(in_val)
	local result = ""
	local state = {
		0x6a09e667,
		0xbb67ae85,
		0x3c6ef372,
		0xa54ff53a,
		0x510e527f,
		0x9b05688c,
		0x1f83d9ab,
		0x5be0cd19,
	}
	in_val = preprocess256(in_val)

	for i = 1, #in_val, 64 do
		digest_block256(in_val, i, state)
	end

	for i = 1, 8 do
		result = result .. ("%08x"):format(state[i])
	end

	return result
end
