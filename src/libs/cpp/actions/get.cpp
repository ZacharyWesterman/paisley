#include "get.hpp"

void get(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	const auto &var_name = vm.get_const(instruction.operand[0]).to_string();

	if (var_name == "@")
	{
		if (!vm.return_indices.empty())
		{
			// If inside a subroutine, get all subroutine arguments
			vm.stack.push(vm.return_indices.back().params);
		}
		else
		{
			// Otherwise, get command-line arguments
			vm.stack.push(vm.argv);
		}
		return;
	}
	else if (var_name == "$")
	{
		// Get all valid commands
		exit(123);
	}
	else if (var_name == "_VARS")
	{
		// Get all variables
		vm.stack.push(vm.variables);
		return;
	}
	else if (var_name == "_VERSION")
	{
		// Get version string
		vm.stack.push(vm.version);
		return;
	}

	if (vm.variables.find(var_name) == vm.variables.end())
	{
		vm.stack.push(Null());
	}
	else
	{
		vm.stack.push(vm.variables[var_name]);
	}
}
