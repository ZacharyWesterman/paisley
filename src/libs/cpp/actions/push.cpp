#include "push.hpp"

void push(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];
	vm.stack.push(vm.get_const(instruction.operand[0]));
}
