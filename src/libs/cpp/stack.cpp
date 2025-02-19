#include "stack.hpp"
#include <iostream>
#include <iomanip>

Value Stack::pop() noexcept
{
	if (empty())
	{
		return Value();
	}

	Value value = std::move(back());
	pop_back();
	return value;
}

void Stack::push(const Value &value) noexcept
{
	push_back(value);
}

void Stack::print() const noexcept
{
	std::cout << "STACK DUMP:" << std::endl;
	int index = 0;
	for (const Value &value : *this)
	{
		// print 2-digit hex index before value
		std::cout << std::hex << std::uppercase << std::setfill('0') << std::setw(2) << index++ << ": " << std::dec;
		std::cout << value.pretty_print() << std::endl;
	}
}
