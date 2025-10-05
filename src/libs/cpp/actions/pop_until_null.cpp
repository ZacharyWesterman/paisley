#include "pop_until_null.hpp"

void _pop_until_null(VirtualMachine &vm) noexcept
{
	// Keep popping until we hit a null or the stack is empty
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

void pop_until_null(VirtualMachine &vm) noexcept
{
	const auto p1 = vm.instructions[vm.instruction_index].operand[0];

	// If p1 is positive, leave that many values on the stack
	if (p1)
	{
		std::vector<Value> keep;
		for (int i = 0; i < p1 && vm.stack.size(); i++)
		{
			if (vm.stack.back().is_null())
			{
				break;
			}
			keep.push_back(vm.stack.pop());
		}

		_pop_until_null(vm);

		// Put the kept values back on the stack in reverse order
		for (auto it = keep.rbegin(); it != keep.rend(); ++it)
		{
			vm.stack.push(*it);
		}
	}
	else
	{
		_pop_until_null(vm);
	}
}
