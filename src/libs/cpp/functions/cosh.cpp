#include "cosh.hpp"

void cosh(Context &context) noexcept
{
	// Hyperbolic cosine of a number.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(std::cosh(param.to_number()));
}
