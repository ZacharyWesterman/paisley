#include "actions.hpp"

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

	pop_catch_or_throw, // This operation is not in the original code, but is called when an exception is thrown
};
const size_t OPERATION_COUNT = 17;
