#include "get.hpp"

void get(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	const auto &var_name = vm.get_const(instruction.operand[0]).to_string();

	if (vm.variables.find(var_name) == vm.variables.end())
	{
		vm.stack.push(Null());
	}
	else
	{
		vm.stack.push(vm.variables[var_name]);
	}
}
