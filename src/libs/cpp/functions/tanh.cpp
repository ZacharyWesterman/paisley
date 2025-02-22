#include "tanh.hpp"

void tanh(Context &context) noexcept
{
	// Hyperbolic tangent of a number.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(std::tanh(param.to_number()));
}
