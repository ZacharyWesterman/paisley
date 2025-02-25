#include "explode.hpp"

void explode(Context &context) noexcept
{
	auto params = context.stack.pop().to_array();
	for (size_t i = params.size(); i > 0; i--)
	{
		context.stack.push(params[i - 1]);
	}
}
