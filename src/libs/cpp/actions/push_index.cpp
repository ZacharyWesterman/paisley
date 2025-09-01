#include "push_index.hpp"

void push_index(VirtualMachine &vm) noexcept
{
	const auto &instruction = vm.instructions[vm.instruction_index];
	const auto &top = vm.stack[vm.stack.size() - 1 - instruction.operand[0]];

	vm.return_indices.push_back({
		vm.instruction_index + 1,
		vm.stack.size() - 1,
		top,
	});
}
