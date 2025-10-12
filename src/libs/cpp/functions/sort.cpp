#include "sort.hpp"
#include <algorithm>

void sort(Context &context) noexcept
{
	auto array = std::get<std::vector<Value>>(context.stack.pop())[0].to_array();
	std::sort(array.begin(), array.end());
	context.stack.push(array);
}
