#include "index.hpp"

void index(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	int index = 0;
	if (std::holds_alternative<std::vector<Value>>(params[0]))
	{
		auto lhs = std::get<std::vector<Value>>(params[0]);
		auto rhs = params[1];

		// Find the index of the rhs in the lhs
		for (int i = 0; i < lhs.size(); i++)
		{
			if (lhs[i] == rhs)
			{
				index = i + 1;
				break;
			}
		}
	}
	else
	{
		auto lhs = params[0].to_string();
		auto rhs = params[1].to_string();

		// Find the index of the rhs in the lhs
		int i = lhs.find(rhs);
		if (i != std::string::npos)
		{
			index = i + 1;
		}
	}

	context.stack.push(index);
}
