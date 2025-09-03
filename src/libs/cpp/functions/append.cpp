#include "append.hpp"

void append(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto lhs = params[0].to_array();
	lhs.push_back(params[1]);
	context.stack.push(lhs);
}
