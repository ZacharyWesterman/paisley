#include "greaterequal.hpp"

void greaterequal(Context &context) noexcept
{
	auto rhs = context.stack.pop();
	auto lhs = context.stack.pop();

	make_comparable(lhs, rhs);

	if (std::holds_alternative<std::string>(lhs))
	{
		context.stack.push(std::get<std::string>(lhs) >= std::get<std::string>(rhs));
	}
	else
	{
		context.stack.push(std::get<double>(lhs) >= std::get<double>(rhs));
	}
}
