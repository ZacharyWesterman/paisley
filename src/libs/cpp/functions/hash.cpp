#include "hash.hpp"
#include <openssl/sha.h>
#include <sstream>
#include <iomanip>

void hash(Context &context) noexcept
{
	// Generate a sha256 hash of a string.
	auto str = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	unsigned char hash[SHA256_DIGEST_LENGTH];
	SHA256((const unsigned char *)str.c_str(), str.size(), hash);

	std::stringstream ss;
	for (int i = 0; i < SHA256_DIGEST_LENGTH; i++)
	{
		ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
	}

	context.stack.push(ss.str());
}
