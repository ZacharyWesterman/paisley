#include "destructure.hpp"
#include <iostream>

void destructure(VirtualMachine &vm) noexcept
{
	const auto values = vm.stack.pop().to_array();
	const auto operand = vm.instructions[vm.instruction_index].operand[0];
	const auto &var_names = std::get<std::vector<Value>>(vm.get_const(operand));

	for (size_t i = 0; i < var_names.size(); i++)
	{
		const auto &var = std::get<std::string>(var_names[i]);
		vm.variables[var] = (i < values.size()) ? values[i] : Value();
	}
}
