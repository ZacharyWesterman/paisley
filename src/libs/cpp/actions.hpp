#pragma once

#include "actions/call.hpp"
#include "actions/set.hpp"
#include "actions/get.hpp"
#include "actions/push.hpp"
#include "actions/pop.hpp"
#include "actions/run_command.hpp"

typedef void (*Operation)(VirtualMachine &) noexcept;
extern const Operation OPERATIONS[];
extern const size_t OPERATION_COUNT;
