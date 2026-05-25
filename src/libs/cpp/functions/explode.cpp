#include "explode.hpp"

#include <sstream>

void explode(Context &context) noexcept
{
	const auto arg = context.stack.pop();
	std::vector<Value> params;

	if (std::holds_alternative<std::string>(arg))
	{
		// Split strings by newline
		std::stringstream stream(std::get<std::string>(arg));
		std::string line;
		while (std::getline(stream, line))
		{
			params.push_back(line);
		}
	}
	else
	{
		params = arg.to_array();
	}

	for (size_t i = params.size(); i > 0; i--)
	{
		context.stack.push(params[i - 1]);
	}
}
