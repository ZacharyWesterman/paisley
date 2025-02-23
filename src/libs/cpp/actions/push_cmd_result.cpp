#include "push_cmd_result.hpp"

void push_cmd_result(VirtualMachine &vm) noexcept
{
	vm.stack.push(vm.last_cmd_result);
}
