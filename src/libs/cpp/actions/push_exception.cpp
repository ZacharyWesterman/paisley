#include "push_exception.hpp"

void push_exception(VirtualMachine &vm) noexcept
{
	auto &instruction = vm.instructions[vm.instruction_index];
	std::vector<Value> arg;

	if (instruction.operand[1])
	{
		arg = std::get<std::vector<Value>>(vm.stack.pop());
	}
	else
	{
		arg = std::get<std::vector<Value>>(vm.get_const(instruction.operand[0]));
	}

	std::map<std::string, Value> err;
	err["message"] = arg[0];
	err["stack"] = std::vector<Value>{instruction.line_no};
	err["type"] = arg[1];
	err["file"] = "unknown";
	err["line"] = instruction.line_no;

	vm.stack.push(err);
}
