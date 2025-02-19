#include "explode.hpp"

void explode(Context &context) noexcept
{
	auto params = context.stack.pop().to_array();
	for (auto &param : params)
	{
		context.stack.push(param);
	}
}
