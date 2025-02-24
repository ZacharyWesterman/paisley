#include "random_elements.hpp"

void random_elements(Context &context) noexcept
{
	// Select (non-repeating) random elements from a list.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto list = params[0].to_array();

	if (list.empty())
	{
		context.stack.push(Null());
		return;
	}

	int count = std::max(0, std::min((int)list.size(), (int)params[1].to_number()));

	std::vector<Value> result;
	std::vector<size_t> indices(list.size());
	std::iota(indices.begin(), indices.end(), 0);

	for (int i = 0; i < count; ++i)
	{
		auto index = context.rng() % indices.size();
		result.push_back(list[indices[index]]);
		indices.erase(indices.begin() + index);
	}

	context.stack.push(result);
}
