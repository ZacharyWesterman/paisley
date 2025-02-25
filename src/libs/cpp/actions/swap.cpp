#include "swap.hpp"

void swap(VirtualMachine &vm) noexcept
{
	// Swap the top two stack elements
	if (vm.stack.size() < 2)
	{
		vm.error("Stack underflow");
		return;
	}

	std::swap(vm.stack[vm.stack.size() - 1], vm.stack[vm.stack.size() - 2]);
}
