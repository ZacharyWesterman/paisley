#include "pop.hpp"

void pop(VirtualMachine &vm) noexcept
{
	vm.stack.pop();
}
