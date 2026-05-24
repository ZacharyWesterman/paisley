#include "pop_goto_index.hpp"

void pop_goto_index(VirtualMachine &vm) noexcept
{
	const auto info = vm.return_indices.back();
	vm.return_indices.pop_back();

	vm.instruction_index = info.index;

	auto &instruction = vm.instructions[vm.instruction_index];
	if (!instruction.operand[0])
	{
		// Put any function return value in the "command return value" slot
		vm.last_cmd_result = vm.stack.pop();

		// Shrink the stack to the size it was before the function call
		vm.stack.resize(info.stack_size);
	}
}
