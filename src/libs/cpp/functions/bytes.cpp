#include "bytes.hpp"

void bytes(Context &context) noexcept
{
	// Split a number into a list of bytes
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	long value = params[0].to_number();
	const int num_bytes = params[1].to_number();

	std::vector<Value> bytes;
	for (int i = 0; i < num_bytes; ++i)
	{
		bytes.push_back(value % 256);
		value /= 256;
	}

	context.stack.push(bytes);
}
