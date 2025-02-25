#include "inarray.hpp"

void inarray(Context &context) noexcept
{
	const auto &data = context.stack.pop();
	const auto &value = context.stack.pop();

	bool result = false;

	if (std::holds_alternative<std::vector<Value>>(data))
	{
		const auto &values = std::get<std::vector<Value>>(data);
		for (const auto &v : values)
		{
			if (v == value)
			{
				result = true;
				break;
			}
		}
	}
	else if (std::holds_alternative<std::map<std::string, Value>>(data))
	{
		const auto &object = std::get<std::map<std::string, Value>>(data);
		const auto key = value.to_string();
		if (object.find(key) != object.end())
		{
			result = true;
		}
	}
	else if (std::holds_alternative<std::string>(data))
	{
		const auto &string = std::get<std::string>(data);
		const auto search = value.to_string();

		if (string.find(search) != std::string::npos)
		{
			result = true;
		}
	}

	context.stack.push(result);
}
