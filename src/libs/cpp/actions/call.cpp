#include "call.hpp"
#include "../context.hpp"
#include "../functions.hpp"
#include "../functions/file_glob.hpp"
#include "../functions/file_exists.hpp"
#include "../functions/file_size.hpp"
#include "../functions/file_read.hpp"
#include "../functions/file_write.hpp"
#include "../functions/file_append.hpp"
#include "../functions/file_delete.hpp"
#include "../functions/dir_create.hpp"
#include "../functions/dir_list.hpp"
#include "../functions/dir_delete.hpp"
#include "../functions/file_type.hpp"
#include "../functions/file_stat.hpp"
#include "../functions/file_copy.hpp"
#include "../functions/file_move.hpp"

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
	if (vm.sandboxed &&
		(function == file_glob ||
		 function == file_exists ||
		 function == file_size ||
		 function == file_read ||
		 function == file_write ||
		 function == file_append ||
		 function == file_delete ||
		 function == dir_create ||
		 function == dir_list ||
		 function == dir_delete ||
		 function == file_type ||
		 function == file_stat ||
		 function == file_copy ||
		 function == file_move))
	{
		vm.error("File operations are not allowed in sandboxed mode!\nYou should never see this message, so one of two things is happening:\n1. There's a bug in the Paisley C++ runtime (in which case, please report it!)\n2. You're poking around in the runtime internals! You hacker :)");
		return;
	}

	function(context);
	if (vm.instruction_index != context.instruction_index)
	{
		vm.instruction_index = context.instruction_index - 1;
	}
}
