#include "virtual_machine.hpp"
#include "actions.hpp"
#include "PAISLEY_BYTECODE.hpp"

#include <iostream>
#include <chrono>
#include <thread>

std::string text_opcode(unsigned char opcode)
{
	switch (opcode)
	{
	case 1:
		return "call";
	case 2:
		return "set";
	case 3:
		return "get";
	case 4:
		return "push";
	case 5:
		return "pop";
	case 6:
		return "run_command";
	case 7:
		return "push_cmd_result";
	case 8:
		return "push_index";
	case 9:
		return "pop_goto_index";
	case 10:
		return "copy";
	case 11:
		return "delete_var";
	case 12:
		return "swap";
	case 13:
		return "pop_until_null";
	case 14:
		return "get_cache_else_jump";
	case 15:
		return "set_cache";
	case 16:
		return "delete_cache";
	case 17:
		return "push_catch_loc";
	default:
		return "unknown";
	}
}

std::string func_text(int code)
{
	switch (code)
	{
	case 1:
		return "jump";
	case 2:
		return "jumpifnil";
	case 3:
		return "jumpiffalse";
	case 4:
		return "explode";
	case 5:
		return "implode";
	case 6:
		return "superimplode";
	case 7:
		return "add";
	case 8:
		return "sub";
	case 9:
		return "mul";
	case 10:
		return "div";
	case 11:
		return "rem";
	case 12:
		return "length";
	case 13:
		return "arrayindex";
	case 14:
		return "arrayslice";
	case 15:
		return "concat";
	case 16:
		return "booland";
	case 17:
		return "boolor";
	case 18:
		return "boolxor";
	case 19:
		return "inarray";
	case 20:
		return "strlike";
	case 21:
		return "equal";
	case 22:
		return "notequal";
	case 23:
		return "greater";
	case 24:
		return "greaterequal";
	case 25:
		return "less";
	case 26:
		return "lessequal";
	case 27:
		return "boolnot";
	case 28:
		return "varexists";
	case 29:
		return "random_int";
	case 30:
		return "random_float";
	case 31:
		return "word_diff";
	case 32:
		return "dist";
	case 33:
		return "sin";
	case 34:
		return "cos";
	case 35:
		return "tan";
	case 36:
		return "asin";
	case 37:
		return "acos";
	case 38:
		return "atan";
	case 39:
		return "atan2";
	case 40:
		return "sqrt";
	case 41:
		return "sum";
	case 42:
		return "mult";
	case 43:
		return "pow";
	case 44:
		return "min";
	case 45:
		return "max";
	case 46:
		return "split";
	case 47:
		return "join";
	case 48:
		return "type";
	case 49:
		return "_bool";
	case 50:
		return "num";
	case 51:
		return "str";
	case 52:
		return "floor";
	case 53:
		return "ceil";
	case 54:
		return "round";
	case 55:
		return "abs";
	case 56:
		return "append";
	case 57:
		return "index";
	case 58:
		return "lower";
	case 59:
		return "upper";
	case 60:
		return "camel";
	case 61:
		return "replace";
	case 62:
		return "json_encode";
	case 63:
		return "json_decode";
	case 64:
		return "json_valid";
	case 65:
		return "b64_encode";
	case 66:
		return "b64_decode";
	case 67:
		return "lpad";
	case 68:
		return "rpad";
	case 69:
		return "hex";
	case 70:
		return "filter";
	case 71:
		return "matches";
	case 72:
		return "clocktime";
	case 73:
		return "reverse";
	case 74:
		return "sort";
	case 75:
		return "bytes";
	case 76:
		return "frombytes";
	case 77:
		return "merge";
	case 78:
		return "update";
	case 79:
		return "insert";
	case 80:
		return "_delete";
	case 81:
		return "lerp";
	case 82:
		return "random_element";
	case 83:
		return "hash";
	case 84:
		return "object";
	case 85:
		return "array";
	case 86:
		return "keys";
	case 87:
		return "values";
	case 88:
		return "pairs";
	case 89:
		return "interleave";
	case 90:
		return "unique";
	case 91:
		return "_union";
	case 92:
		return "intersection";
	case 93:
		return "difference";
	case 94:
		return "symmetric_difference";
	case 95:
		return "is_disjoint";
	case 96:
		return "is_subset";
	case 97:
		return "is_superset";
	case 98:
		return "count";
	case 99:
		return "find";
	case 100:
		return "flatten";
	case 101:
		return "smoothstep";
	case 102:
		return "sinh";
	case 103:
		return "cosh";
	case 104:
		return "tanh";
	case 105:
		return "sign";
	case 106:
		return "ascii";
	case 107:
		return "_char";
	case 108:
		return "beginswith";
	case 109:
		return "endswith";
	case 110:
		return "numeric_string";
	case 111:
		return "time";
	case 112:
		return "date";
	case 113:
		return "random_elements";
	case 114:
		return "match";
	case 115:
		return "splice";
	default:
		return "unknown";
	}
}

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

		// Command-line arguments
		{},
	};

	// Fill in command-line arguments
	vm.argv.reserve(argc - 1);
	for (int i = 1; i < argc; i++)
	{
		vm.argv.push_back(argv[i]);
	}

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

		// // Print the list of instructions
		// for (size_t i = 0; i < vm.instructions.size(); i++)
		// {
		// 	std::cout << i + 1 << " @ line ";
		// 	std::cout << vm.instructions[i].line_no << " ";

		// 	std::cout << (i == vm.instruction_index ? "> " : "  ") << text_opcode(vm.instructions[i].opcode);

		// 	std::cout << " " << (vm.instructions[i].opcode == 1 ? func_text(vm.instructions[i].operand[0] + 1) : std::to_string(vm.instructions[i].operand[0])) << " " << vm.instructions[i].operand[1] << std::endl;
		// }
		// std::cout << std::endl;

		// // Print the stack
		// vm.stack.print();
		// std::cout << std::endl;

		// // Print the call stack
		// std::cout << "Call stack:" << std::endl;
		// for (size_t i = 0; i < vm.return_indices.size(); i++)
		// {
		// 	std::cout << vm.return_indices[i].index << std::endl;
		// 	std::cout << vm.return_indices[i].stack_size << std::endl;
		// 	std::cout << vm.return_indices[i].params.pretty_print() << std::endl;
		// }
		// std::cout << std::endl;

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

		// (void)std::cin.get();
	}

	return 0;
}
