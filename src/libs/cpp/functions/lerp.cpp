#include "lerp.hpp"

void lerp(Context &context) noexcept
{
	// Linear interpolation between two numbers.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto ratio = params[0].to_number();
	auto start = params[1].to_number();
	auto stop = params[2].to_number();

	context.stack.push(start + ratio * (stop - start));
}
