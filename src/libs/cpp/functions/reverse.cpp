#include "reverse.hpp"
#include <algorithm>

void reverse(Context &context) noexcept
{
	// Reverse an array or string
	auto value = std::get<std::vector<Value>>(context.stack.pop())[0];

	if (std::holds_alternative<std::string>(value))
	{
		auto str = std::get<std::string>(value);
		std::reverse(str.begin(), str.end());
		context.stack.push(str);
	}
	else
	{
		auto array = value.to_array();
		std::reverse(array.begin(), array.end());
		context.stack.push(array);
	}
}
