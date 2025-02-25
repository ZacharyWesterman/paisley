#include "sign.hpp"

void sign(Context &context) noexcept
{
	// Sign of a number.
	auto param = std::get<std::vector<Value>>(context.stack.pop())[0];
	context.stack.push(std::signbit(param.to_number()) ? -1 : 1);
}
