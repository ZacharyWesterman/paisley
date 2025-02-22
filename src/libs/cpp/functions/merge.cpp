#include "merge.hpp"

void merge(Context &context) noexcept
{
	// Concatenate two arrays
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto array1 = params[0].to_array();
	auto array2 = params[1].to_array();

	array1.reserve(array1.size() + array2.size());
	array1.insert(array1.end(), array2.begin(), array2.end());

	context.stack.push(array1);
}
