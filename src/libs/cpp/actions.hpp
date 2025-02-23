#pragma once

#include "actions/call.hpp"
#include "actions/set.hpp"
#include "actions/get.hpp"
#include "actions/push.hpp"
#include "actions/pop.hpp"
#include "actions/run_command.hpp"
#include "actions/push_cmd_result.hpp"
#include "actions/push_index.hpp"
#include "actions/pop_goto_index.hpp"
#include "actions/copy.hpp"
#include "actions/delete_var.hpp"
#include "actions/swap.hpp"
#include "actions/pop_until_null.hpp"
#include "actions/get_cache_else_jump.hpp"
#include "actions/set_cache.hpp"
#include "actions/delete_cache.hpp"
#include "actions/push_catch_loc.hpp"

typedef void (*Operation)(VirtualMachine &) noexcept;
extern const Operation OPERATIONS[];
extern const size_t OPERATION_COUNT;
