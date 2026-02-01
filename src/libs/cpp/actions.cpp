#include "actions.hpp"

#include "actions/call.hpp"
#include "actions/copy.hpp"
#include "actions/delete_cache.hpp"
#include "actions/delete_var.hpp"
#include "actions/destructure.hpp"
#include "actions/get_cache_else_jump.hpp"
#include "actions/get.hpp"
#include "actions/pop_catch_or_throw.hpp"
#include "actions/pop_goto_index.hpp"
#include "actions/pop_until_null.hpp"
#include "actions/pop.hpp"
#include "actions/push_catch_loc.hpp"
#include "actions/push_cmd_result.hpp"
#include "actions/push_index.hpp"
#include "actions/push.hpp"
#include "actions/run_command.hpp"
#include "actions/set_cache.hpp"
#include "actions/set.hpp"
#include "actions/swap.hpp"
#include "actions/variable_insert.hpp"

const Operation OPERATIONS[] = {
	call,
	set,
	get,
	push,
	pop,
	run_command,
	push_cmd_result,
	push_index,
	pop_goto_index,
	copy,
	delete_var,
	swap,
	pop_until_null,
	get_cache_else_jump,
	set_cache,
	delete_cache,
	push_catch_loc,
	variable_insert,
	destructure,

	pop_catch_or_throw, // This operation is not in the original code, but is called when an exception is thrown
};
const size_t OPERATION_COUNT = sizeof(OPERATIONS) / sizeof(OPERATIONS[0]) - 1;
