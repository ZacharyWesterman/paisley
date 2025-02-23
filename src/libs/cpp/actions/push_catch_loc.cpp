#include "push_catch_loc.hpp"

void push_catch_loc(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	const ExceptStackInfo info = {
		(size_t)instruction.operand[0],
		vm.stack.size(),
		vm.instruction_index,
	};
	vm.except_stack.push_back(info);
}
