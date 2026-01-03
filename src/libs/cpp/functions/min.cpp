#include "min.hpp"
#include <limits>

void min(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	bool found_value = false;
	double result = std::numeric_limits<double>::max();

	for (const Value &value : params)
	{
		if (std::holds_alternative<std::vector<Value>>(value))
		{
			for (const Value &inner_value : std::get<std::vector<Value>>(value))
			{
				result = std::min(result, inner_value.to_number());
				found_value = true;
			}
		}
		else
		{
			result = std::min(result, value.to_number());
			found_value = true;
		}
	}

	if (found_value)
	{
		context.stack.push(result);
	}
	else
	{
		// If there's no value in the params, push null.
		context.stack.push(Null());
	}
}
