#include "div.hpp"
#include <limits>

void div(Context &context) noexcept
{
	auto b = context.stack.pop().to_number();
	auto a = context.stack.pop().to_number();

	// Safely divide. If b is 0, return infinity.
	auto result = (b == 0) ? std::numeric_limits<double>::infinity() : a / b;
	context.stack.push(result);
}
