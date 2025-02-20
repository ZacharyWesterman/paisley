#include "round.hpp"
#include <cmath>

void round(Context &context) noexcept
{
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0].to_number();
	context.stack.push(std::round(value));
}
