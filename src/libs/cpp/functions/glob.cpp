#include "glob.hpp"
#include "../replace.hpp"

void glob(Context &context) noexcept
{
	auto values = std::get<std::vector<Value>>(context.stack.pop());
	auto pattern = values[0].to_string();

	std::vector<Value> result;

	// Replace all occurences of "*" with the appropriate string.
	for (size_t i = 1; i < values.size(); i++)
	{
		if (std::holds_alternative<std::vector<Value>>(values[i]))
		{
			for (auto &value : std::get<std::vector<Value>>(values[i]))
			{
				auto val = replace(pattern, "*", value.to_string());
				result.push_back(val);
			}
		}
		else
		{
			auto val = replace(pattern, "*", values[i].to_string());
			result.push_back(val);
		}
	}

	context.stack.push(result);
}
