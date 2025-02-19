#include "implode.hpp"
#include <algorithm>

void implode(Context &context) noexcept
{
	std::vector<Value> items;
	for (int i = 0; i < context.arg.x; i++)
	{
		items.push_back(context.stack.pop());
	}

	std::reverse(items.begin(), items.end());
	context.stack.push(items);
}
