#include "copy.hpp"

void copy(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	size_t index = vm.stack.size() - instruction.operand[0] - 1;

	if (index >= vm.stack.size())
	{
		vm.error("Invalid stack index");
		return;
	}

	vm.stack.push(vm.stack[index]);
}
