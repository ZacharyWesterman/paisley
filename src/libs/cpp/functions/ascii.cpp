#include "ascii.hpp"

void ascii(Context &context) noexcept
{
	// Convert a number to a character.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(std::string(1, static_cast<char>(param.to_number())));
}
