#pragma once

#include "virtual_machine.hpp"

typedef void (*Operation)(VirtualMachine &);
extern const Operation OPERATIONS[];
extern const size_t OPERATION_COUNT;
