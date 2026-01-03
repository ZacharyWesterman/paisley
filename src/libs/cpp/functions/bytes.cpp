#include "bytes.hpp"

void bytes(Context &context) noexcept
{
	// Split a number into a list of bytes
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	long value = params[0].to_number();
	const int num_bytes = params[1].to_number();

	std::vector<Value> bytes;
	bytes.reserve(num_bytes);

	for (int offset = (num_bytes - 1) * 8; offset >= 0; offset -= 8)
	{
		const long byte = (value >> offset) & 0xff;
		bytes.push_back(byte);
	}

	context.stack.push(bytes);
}
