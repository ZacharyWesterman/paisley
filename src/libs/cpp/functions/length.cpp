#include "length.hpp"

void length(Context &context) noexcept
{
	auto value = context.stack.pop();

	double result = 0;

	// Length only makes sense for strings and arrays
	if (std::holds_alternative<std::string>(value))
	{
		result = static_cast<double>(std::get<std::string>(value).size());
	}
	else if (std::holds_alternative<std::vector<Value>>(value))
	{
		result = static_cast<double>(std::get<std::vector<Value>>(value).size());
	}

	context.stack.push(result);
}
