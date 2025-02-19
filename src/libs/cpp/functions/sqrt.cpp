#include "sqrt.hpp"

void sqrt(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto value = params[0].to_number();

	context.stack.push(std::sqrt(value));
}
