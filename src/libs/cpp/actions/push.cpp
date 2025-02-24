#include "push.hpp"

void push(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	const auto &constant = vm.get_const(instruction.operand[0]);
	vm.stack.push(constant);
}
