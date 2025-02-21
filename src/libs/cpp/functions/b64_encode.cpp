#include "b64_encode.hpp"

void b64_encode(Context &context) noexcept
{
	// Encode a string to base64
	auto str = std::get<std::vector<Value>>(context.stack.pop())[0].to_string();

	std::string encoded;
	encoded.reserve(((str.size() + 2) / 3) * 4);

	static const char *base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	size_t i = 0;
	while (i < str.size())
	{
		uint32_t octet_a = i < str.size() ? (unsigned char)str[i++] : 0;
		uint32_t octet_b = i < str.size() ? (unsigned char)str[i++] : 0;
		uint32_t octet_c = i < str.size() ? (unsigned char)str[i++] : 0;

		uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;

		encoded.push_back(base64[(triple >> 3 * 6) & 0x3F]);
		encoded.push_back(base64[(triple >> 2 * 6) & 0x3F]);
		encoded.push_back(base64[(triple >> 1 * 6) & 0x3F]);
		encoded.push_back(base64[(triple >> 0 * 6) & 0x3F]);
	}

	switch (str.size() % 3)
	{
	case 1:
		encoded[encoded.size() - 1] = '=';
		encoded[encoded.size() - 2] = '=';
		break;
	case 2:
		encoded[encoded.size() - 2] = '=';
		break;
	}

	context.stack.push(encoded);
}
