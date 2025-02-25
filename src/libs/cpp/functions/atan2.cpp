#include "atan2.hpp"

void atan2(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto x = params[0].to_number();
	auto y = params[1].to_number();

	context.stack.push(std::atan2(x, y));
}
