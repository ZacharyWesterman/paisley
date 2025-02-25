#include "split.hpp"

void split(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto str = params[0].to_string();
	auto delimiter = params[1].to_string();

	std::vector<Value> result;

	if (delimiter.empty())
	{
		for (char c : str)
		{
			result.push_back(std::string(1, c));
		}
	}
	else
	{
		size_t start = 0;
		size_t end = str.find(delimiter);

		while (end != std::string::npos)
		{
			result.push_back(str.substr(start, end - start));
			start = end + delimiter.length();
			end = str.find(delimiter, start);
		}
		result.push_back(str.substr(start, end));
	}

	context.stack.push(result);
}
