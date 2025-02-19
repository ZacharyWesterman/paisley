#include "mult.hpp"

void mult(Context &context) noexcept
{
	auto b = context.stack.pop();
	auto a = context.stack.pop();
	context.stack.push(a.to_number() * b.to_number());
}
