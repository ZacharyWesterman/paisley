#include "log.hpp"
#include <math.h>

void log(Context &context) noexcept
{
	auto values = std::get<std::vector<Value>>(context.stack.pop());
	auto number = values[0].to_number();
	auto base = values[1];

	auto result = log(number);
	if (!base.is_null())
	{
		result = log(number) / log(base.to_number());
	}

	context.stack.push(result);
}
