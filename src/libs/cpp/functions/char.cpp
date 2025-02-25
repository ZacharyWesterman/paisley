#include "char.hpp"

void _char(Context &context) noexcept
{
	// Convert a character to a number.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(static_cast<double>(param.to_string()[0]));
}
