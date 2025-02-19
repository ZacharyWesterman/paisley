#include "implode.hpp"

void implode(Context &context) noexcept
{
	std::vector<Value> items;
	for (int i = 0; i < context.arg.x; i++)
	{
		items.push_back(context.stack.pop());
	}
	context.stack.push(items);
}
