#include "call.hpp"
#include "../context.hpp"
#include "../functions.hpp"
#include "../functions/file_glob.hpp"

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

	const auto function = FUNCTIONS[instruction.operand[0]];
	if (vm.sandboxed && function == file_glob)
	{
		vm.error("File globbing is not allowed in sandboxed mode!\nYou should never see this message, so one of two things is happening:\n1. There's a bug in the Paisley C++ runtime (in which case, please report it!)\n2. You're poking around in the runtime internals! You hacker :)");
		return;
	}

	function(context);
	if (vm.instruction_index != context.instruction_index)
	{
		vm.instruction_index = context.instruction_index - 1;
	}
}
