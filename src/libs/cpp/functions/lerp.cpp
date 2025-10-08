#include "lerp.hpp"

void lerp(Context &context) noexcept
{
	// Linear interpolation between two numbers or vectors.
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto ratio = params[0].to_number();
	auto a = params[1];
	auto b = params[2];

	if (std::holds_alternative<std::vector<Value>>(a) || std::holds_alternative<std::vector<Value>>(b))
	{
		auto arr_a = a.to_array();
		auto arr_b = b.to_array();
		auto len = std::min(arr_a.size(), arr_b.size());

		std::vector<Value> result;
		result.reserve(len);

		for (size_t i = 0; i < len; ++i)
		{
			auto start = arr_a[i].to_number();
			auto stop = arr_b[i].to_number();
			result.push_back(start + ratio * (stop - start));
		}
		context.stack.push(result);
		return;
	}

	auto start = a.to_number();
	auto stop = b.to_number();
	context.stack.push(start + ratio * (stop - start));
}
