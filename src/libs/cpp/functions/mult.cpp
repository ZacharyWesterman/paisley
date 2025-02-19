#include "mult.hpp"

void mult(Stack &stack) noexcept
{
	auto b = stack.pop();
	auto a = stack.pop();
	stack.push(a.to_number() * b.to_number());
}
