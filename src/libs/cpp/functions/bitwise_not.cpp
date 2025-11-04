#include "bitwise_not.hpp"

void bitwise_not(Context &context) noexcept
{
	const double value = ~(long)(context.stack.pop().to_number());
	context.stack.push(value);
}
