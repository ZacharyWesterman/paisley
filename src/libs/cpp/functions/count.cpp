#include "count.hpp"

void count(Context &context) noexcept
{
	// Count the number of occurrences of a value in an array or string.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	int count = 0;

	if (std::holds_alternative<std::vector<Value>>(params[0]))
	{
		auto array = std::get<std::vector<Value>>(params[0]);
		Value value = params[1];

		for (const Value &element : array)
		{
			if (element == value)
			{
				count++;
			}
		}
	}
	else if (std::holds_alternative<std::string>(params[0]))
	{
		std::string str = std::get<std::string>(params[0]);
		std::string substr = std::get<std::string>(params[1]);

		size_t pos = 0;
		while ((pos = str.find(substr, pos)) != std::string::npos)
		{
			count++;
			pos += substr.length();
		}
	}
	else
	{
		context.warn("Count requires an array or a string and a value. Result may be unexpected.");
	}

	context.stack.push(count);
}
