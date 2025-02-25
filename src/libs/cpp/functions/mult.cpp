#include "mult.hpp"

void mult(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	double total = 1;
	for (const Value &value : params)
	{
		if (std::holds_alternative<std::vector<Value>>(value))
		{
			for (const Value &inner_value : std::get<std::vector<Value>>(value))
			{
				total *= inner_value.to_number();
			}
		}
		else
		{
			total *= value.to_number();
		}
	}
	context.stack.push(total);
}
