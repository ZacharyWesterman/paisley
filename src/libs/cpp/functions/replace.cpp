#include "replace.hpp"

void replace(Context &context) noexcept
{
	// Replace all occurrences of a substring in a string
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	auto str = params[0].to_string();
	auto search = params[1].to_string();
	auto replace = params[2].to_string();

	size_t pos = 0;
	while ((pos = str.find(search, pos)) != std::string::npos)
	{
		str.replace(pos, search.length(), replace);
		pos += replace.length();
	}

	context.stack.push(str);
}
