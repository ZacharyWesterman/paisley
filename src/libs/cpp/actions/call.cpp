#include "call.hpp"
#include "../context.hpp"
#include "../functions.hpp"

void call(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];

	Context context = {
		vm.stack,
		vm.variables,
		vm.rng,
		vm.instruction_index,
		instruction.operand[1],
		instruction.line_no,
	};

	if (instruction.operand[0] < 0 || instruction.operand[0] >= FUNCTION_COUNT)
	{
		vm.error("Invalid function index");
		return;
	}

	FUNCTIONS[instruction.operand[0]](context);
	vm.instruction_index = context.instruction_index;
}
