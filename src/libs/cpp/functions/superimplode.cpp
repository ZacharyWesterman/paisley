#include "superimplode.hpp"
#include <algorithm>

void superimplode(Context &context) noexcept
{
	std::vector<Value> items;
	for (int i = 0; i < context.arg; i++)
	{
		auto item = context.stack.pop();
		if (std::holds_alternative<std::vector<Value>>(item))
		{
			auto subset = std::get<std::vector<Value>>(item);
			std::reverse(subset.begin(), subset.end());
			for (const Value &value : subset)
			{
				items.push_back(value);
			}
		}
		else
		{
			items.push_back(item);
		}
	}

	std::reverse(items.begin(), items.end());
	context.stack.push(items);
}
