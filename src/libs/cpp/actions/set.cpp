#include "set.hpp"

void set(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];
	const auto &var_name = vm.get_const(instruction.operand[0]).to_string();
	vm.variables[var_name] = vm.stack.pop();
}
