#include "pop_catch_or_throw.hpp"

#include <iostream>

void pop_catch_or_throw(VirtualMachine &vm) noexcept
{
	auto line_no = vm.instructions[vm.instruction_index].line_no;
	auto msg = std::get<std::string>(vm.stack.pop());

	if (vm.except_stack.empty())
	{
		std::cerr << "ERROR: [line " << line_no << "] " << msg << std::endl;
		std::cerr << "Error not caught, program terminated." << std::endl;
		std::exit(1);
	}

	auto &info = vm.except_stack.back();
	vm.except_stack.pop_back();

	vm.instruction_index = info.goto_index - 1;
	vm.stack.resize(info.stack_size);

	// Pop the call stack
	std::vector<Value> call_stack;
	call_stack.reserve(vm.return_indices.size() - info.return_stack_size + 1);
	for (size_t i = info.return_stack_size + 1; i < vm.return_indices.size(); i++)
	{
		int stack_line_no = vm.instructions[vm.return_indices[i].index].line_no;
		call_stack.push_back(stack_line_no);
	}
	call_stack.push_back(line_no);

	if (info.return_stack_size)
	{
		line_no = vm.instructions[vm.return_indices[info.return_stack_size].index].line_no;
	}
	vm.return_indices.resize(info.return_stack_size);

	vm.stack.push(std::map<std::string, Value>{
		{"message", msg},
		{"line", line_no},
		{"stack", call_stack},
	});
}
