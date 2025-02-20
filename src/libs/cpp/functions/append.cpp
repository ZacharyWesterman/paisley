#include "append.hpp"

void append(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto lhs = params[0].to_array();
	auto rhs = params[1].to_array();

	for (auto &value : rhs)
	{
		lhs.push_back(value);
	}

	context.stack.push(lhs);
}
