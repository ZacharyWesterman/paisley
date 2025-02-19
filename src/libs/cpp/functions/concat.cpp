#include "concat.hpp"

void concat(Context &context) noexcept
{
	auto b = context.stack.pop();
	auto a = context.stack.pop();
	context.stack.push(a.to_string() + b.to_string());
}
