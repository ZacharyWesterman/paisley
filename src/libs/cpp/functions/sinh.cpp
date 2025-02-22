#include "sinh.hpp"

void sinh(Context &context) noexcept
{
	// Hyperbolic sine of a number.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(std::sinh(param.to_number()));
}
