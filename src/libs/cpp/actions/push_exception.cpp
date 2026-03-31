#include "push_exception.hpp"

void push_exception(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];
	Value arg;

	if (instruction.operand[1])
	{
		arg = vm.stack.pop();
	}
	else
	{
		arg = vm.get_const(instruction.operand[0]);
	}

	std::map<std::string, Value> err;
	err["message"] = vm.stack.pop();
	err["stack"] = std::vector<Value>{instruction.line_no};
	err["type"] = arg;
	err["file"] = "unknown";
	err["line"] = instruction.line_no;

	vm.stack.push(err);
}
