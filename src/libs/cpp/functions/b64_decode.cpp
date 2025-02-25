#include "b64_decode.hpp"
#include <cstring>

void b64_decode(Context &context) noexcept
{
	// Decode a base64 string
	auto str = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	static const char *base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	std::string decoded;
	decoded.reserve((str.size() / 4) * 3);

	size_t i = 0;
	while (i < str.size())
	{
		uint32_t sextet_a = str[i] == '=' ? 0 & i++ : strchr(base64, str[i++]) - base64;
		uint32_t sextet_b = str[i] == '=' ? 0 & i++ : strchr(base64, str[i++]) - base64;
		uint32_t sextet_c = str[i] == '=' ? 0 & i++ : strchr(base64, str[i++]) - base64;
		uint32_t sextet_d = str[i] == '=' ? 0 & i++ : strchr(base64, str[i++]) - base64;

		uint32_t triple = (sextet_a << 3 * 6) + (sextet_b << 2 * 6) + (sextet_c << 1 * 6) + (sextet_d << 0 * 6);

		decoded.push_back((triple >> 2 * 8) & 0xFF);
		decoded.push_back((triple >> 1 * 8) & 0xFF);
		decoded.push_back((triple >> 0 * 8) & 0xFF);
	}

	context.stack.push(decoded);
}
