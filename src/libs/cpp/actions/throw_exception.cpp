#include "throw_exception.hpp"

#include <iostream>

void throw_exception(VirtualMachine &vm) noexcept
{
	auto err = std::get<std::map<std::string, Value>>(vm.stack.back());
	auto &err_stack = std::get<std::vector<Value>>(err["stack"]);

	if (vm.except_stack.empty())
	{
		// If exception is not caught, end the program immediately and output the error.
		auto message = std::get<std::string>(err["message"]);
		auto line = (int)std::get<double>(err["line"]);
		std::cerr << "ERROR: [line " << line << "] " << message << std::endl;
		std::cerr << "Error not caught, program terminated." << std::endl;
		std::exit(1);
	}

	// Otherwise, we are catching exceptions.

	// Unroll program stack
	auto &info = vm.except_stack.back();
	vm.except_stack.pop_back();
	vm.stack.resize(info.stack_size);

	// Unroll call stack
	while (vm.return_indices.size() > info.return_stack_size)
	{
		auto retn = vm.return_indices.back();
		vm.return_indices.pop_back();
		auto line = vm.instructions[retn.index].line_no;
		std::get<std::vector<Value>>(err["line"]).push_back(line);
	}

	vm.instruction_index = info.goto_index - 1;
	err["line"] = err_stack.back();

	vm.stack.push(err);
}
