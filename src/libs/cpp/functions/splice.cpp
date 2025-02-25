#include "splice.hpp"

void splice(Context &context) noexcept
{
	// Splice an array.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto list = params[0].to_array();
	int start = params[1].to_number();
	int end = params[2].to_number();
	auto replacement = params[3].to_array();

	if (start == 0 || end == 0)
	{
		context.warn("Array indices start with 1, not 0.");
	}

	if (start >= 0)
	{
		start--;
	}
	if (end >= 0)
	{
		end--;
	}

	if (start < 0)
	{
		start = list.size() + start;
	}

	if (end < 0)
	{
		end = list.size() + end;
	}

	start = std::max(0, std::min(start, (int)list.size()));
	end = std::max(0, std::min(end, (int)list.size()));

	std::vector<Value> result;
	result.reserve(list.size() + replacement.size() - (end - start));

	for (int i = 0; i < start; i++)
	{
		result.push_back(list[i]);
	}

	for (const Value &value : replacement)
	{
		result.push_back(value);
	}

	for (int i = end; i < (int)list.size(); i++)
	{
		result.push_back(list[i]);
	}

	context.stack.push(result);
}
