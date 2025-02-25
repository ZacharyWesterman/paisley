#include "join.hpp"

void join(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto values = params[0].to_array();
	auto delimiter = params[1].to_string();

	std::string result;

	for (size_t i = 0; i < values.size(); ++i)
	{
		if (i)
		{
			result += delimiter;
		}
		result += values[i].to_string();
	}

	context.stack.push(result);
}
