#include "asin.hpp"

void asin(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto value = params[0].to_number();

	context.stack.push(std::asin(value));
}
