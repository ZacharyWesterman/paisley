#include "pop_until_null.hpp"

void pop_until_null(VirtualMachine &vm) noexcept
{
	while (vm.stack.size())
	{
		const auto &top = vm.stack.back();
		vm.stack.pop();
		if (std::holds_alternative<Null>(top))
		{
			break;
		}
	}
}
