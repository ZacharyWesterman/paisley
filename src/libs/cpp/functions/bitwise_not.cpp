#include "bitwise_not.hpp"

void bitwise_not(Context &context) noexcept
{
	const auto &value = context.stack.pop();
	context.stack.push(~(long)value.to_number());
}
