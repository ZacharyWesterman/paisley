#include "filter.hpp"
#include "../match.hpp"

void filter(Context &context) noexcept
{
	// Remove all characters from a string that do not match the given pattern
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	const auto &str = params[0].to_string();
	const auto &pattern = params[1].to_string();

	std::string result;
	result.reserve(str.size());

	for (const char &c : str)
	{
		if (lua_match(std::string(1, c), '^' + pattern).size())
		{
			result.push_back(c);
		}
	}

	context.stack.push(result);
}
