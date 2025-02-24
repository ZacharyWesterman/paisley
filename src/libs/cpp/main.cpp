#include "virtual_machine.hpp"
#include "actions.hpp"
#include "PAISLEY_BYTECODE.hpp"

#include <iostream>

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;

	VirtualMachine vm = {
		// Stack
		{},

		// Variables
		{},

		// Random number generator
		std::mt19937_64(),

		// Instruction index
		0,

		// Instructions
		INSTRUCTIONS,

		// Constant lookup table
		CONSTANTS,

		// Last command result
		{},

		// Subroutine cache
		{},

		// Return indices
		{},

		// Exception stack
		{},
	};

	vm.rng.seed(std::random_device()());

	while (vm.instruction_index < vm.instructions.size())
	{
		auto &instruction = vm.instructions[vm.instruction_index];

		size_t opcode = instruction.opcode - 1;
		if (opcode > OPERATION_COUNT)
		{
			vm.error("Invalid opcode: " + std::to_string(instruction.opcode));
			break;
		}

		try
		{
			OPERATIONS[opcode](vm);
		}
		catch (const std::exception &e)
		{
			vm.stack.push(e.what());
			OPERATIONS[OPERATION_COUNT](vm);
		}

		vm.instruction_index++;
	}

	return 0;
}
