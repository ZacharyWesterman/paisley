#include "cos.hpp"

void cos(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto value = params[0].to_number();

	context.stack.push(std::cos(value));
}
