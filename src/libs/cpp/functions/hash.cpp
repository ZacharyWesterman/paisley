#include "hash.hpp"

#include <array>
#include <cstdint>
#include <sstream>
#include <iomanip>

constexpr std::array<uint32_t, 64> round_constants = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};

constexpr std::array<uint32_t, 8> initial_hash = {
	0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};

constexpr uint32_t rotate_right(uint32_t value, uint32_t count)
{
	return (value >> count) | (value << (32 - count));
}

std::string sha256(const std::string &message)
{
	std::string padded = message;
	const uint64_t bit_length = static_cast<uint64_t>(message.size()) * 8;
	padded.push_back(0x80);
	while ((padded.size() + 8) % 64 != 0)
	{
		padded.push_back('\0');
	}

	for (int shift = 56; shift >= 0; shift -= 8)
	{
		padded.push_back((bit_length >> shift) & 0xff);
	}

	auto hash = initial_hash;
	for (size_t chunk_start = 0; chunk_start < padded.size(); chunk_start += 64)
	{
		std::array<uint32_t, 64> words = {};
		for (size_t i = 0; i < 16; i++)
		{
			const auto byte = reinterpret_cast<const unsigned char *>(padded.data() + chunk_start + i * 4);
			words[i] = (static_cast<uint32_t>(byte[0]) << 24) |
					   (static_cast<uint32_t>(byte[1]) << 16) |
					   (static_cast<uint32_t>(byte[2]) << 8) |
					   static_cast<uint32_t>(byte[3]);
		}

		for (size_t i = 16; i < words.size(); i++)
		{
			const uint32_t s0 = rotate_right(words[i - 15], 7) ^ rotate_right(words[i - 15], 18) ^ (words[i - 15] >> 3);
			const uint32_t s1 = rotate_right(words[i - 2], 17) ^ rotate_right(words[i - 2], 19) ^ (words[i - 2] >> 10);
			words[i] = words[i - 16] + s0 + words[i - 7] + s1;
		}

		uint32_t a = hash[0], b = hash[1], c = hash[2], d = hash[3];
		uint32_t e = hash[4], f = hash[5], g = hash[6], h = hash[7];
		for (size_t i = 0; i < words.size(); i++)
		{
			const uint32_t s1 = rotate_right(e, 6) ^ rotate_right(e, 11) ^ rotate_right(e, 25);
			const uint32_t choice = (e & f) ^ (~e & g);
			const uint32_t temp1 = h + s1 + choice + round_constants[i] + words[i];
			const uint32_t s0 = rotate_right(a, 2) ^ rotate_right(a, 13) ^ rotate_right(a, 22);
			const uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
			const uint32_t temp2 = s0 + majority;

			h = g;
			g = f;
			f = e;
			e = d + temp1;
			d = c;
			c = b;
			b = a;
			a = temp1 + temp2;
		}

		hash[0] += a;
		hash[1] += b;
		hash[2] += c;
		hash[3] += d;
		hash[4] += e;
		hash[5] += f;
		hash[6] += g;
		hash[7] += h;
	}

	std::ostringstream result;
	result << std::hex << std::setfill('0');
	for (const uint32_t value : hash)
	{
		result << std::setw(8) << value;
	}
	return result.str();
}

void hash(Context &context) noexcept
{
	auto str = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();
	context.stack.push(sha256(str));
}
