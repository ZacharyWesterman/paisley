#include "find.hpp"

void find(Context &context) noexcept
{
	// Find the index of the nth occurrence of a value in an array or string.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	int nth_occurrence = params[3].to_number();
	int index = -1;
	int occurrence = 0;

	if (std::holds_alternative<std::vector<Value>>(params[0]))
	{
		auto array = std::get<std::vector<Value>>(params[0]);
		Value value = params[1];

		for (size_t i = 0; i < array.size(); i++)
		{
			if (array[i] == value)
			{
				index = i;
				occurrence++;
				if (occurrence >= nth_occurrence)
				{
					break;
				}
			}
		}
	}
	else
	{
		std::string str = params[0].to_string();
		std::string substr = std::get<std::string>(params[1]);

		for (int i = 0; i < nth_occurrence; i++)
		{
			size_t pos = str.find(substr, index + 1);
			if (pos == std::string::npos)
			{
				index = -1;
				break;
			}
			index = pos;
			occurrence++;
		}
	}

	context.stack.push((occurrence >= nth_occurrence) ? index + 1 : 0);
}
