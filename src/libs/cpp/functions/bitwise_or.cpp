#include "bitwise_or.hpp"

void bitwise_or(Context &context) noexcept
{
	const auto &rhs = context.stack.pop();
	const auto &lhs = context.stack.pop();
	context.stack.push((long)lhs.to_number() | (long)rhs.to_number());
}
