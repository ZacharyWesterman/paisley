#include "varexists.hpp"

void varexists(Context &context) noexcept
{
	auto key = context.stack.pop().to_string();
	context.stack.push(context.variables.has(key));
}
