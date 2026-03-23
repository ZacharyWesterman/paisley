#include "get_exception_type.hpp"

void get_exception_type(VirtualMachine &vm) noexcept
{
	auto exception = std::get<std::map<std::string, Value>>(vm.stack.back());
	vm.stack.push(exception["type"]);
}
