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

		// std::cout << "Instruction: " << vm.instruction_index << std::endl;
		// std::cout << "Opcode: " << (int)instruction.opcode << std::endl;
		// std::cout << "Line number: " << instruction.line_no << std::endl;
		// std::cout << "Operand 0: " << instruction.operand[0] << std::endl;
		// std::cout << "Operand 1: " << instruction.operand[1] << std::endl;
		// vm.stack.print();
		// std::cout << std::endl;

		OPERATIONS[opcode](vm);
		vm.instruction_index++;
	}

	return 0;
}
