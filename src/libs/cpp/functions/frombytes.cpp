#include "frombytes.hpp"

void frombytes(Context &context) noexcept
{
	// Convert a list of bytes into a number
	auto bytes = std::get<std::vector<Value>>(context.stack.pop());
	int result = 0;
	for (const Value &byte : bytes)
	{
		result *= 256;
		result += static_cast<int>(byte.to_number()) % 256;
	}
	context.stack.push(result);
}
