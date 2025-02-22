#include "random_element.hpp"

void random_element(Context &context) noexcept
{
	// Select a random element from a list.
	auto list = std::get<std::vector<Value>>(context.stack.pop())[0].to_array();

	if (list.empty())
	{
		context.stack.push(Value());
		return;
	}

	auto index = context.rng() % list.size();
	context.stack.push(list[index]);
}
