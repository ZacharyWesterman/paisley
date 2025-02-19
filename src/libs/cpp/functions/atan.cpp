#include "atan.hpp"

void atan(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto value = params[0].to_number();

	context.stack.push(std::atan(value));
}
