#include "stack.hpp"
#include "context.hpp"
#include "functions.hpp"

// Typedef for functions of type void(Context &)
typedef void (*Function)(Context &);

// A list of all possible functions
const Function functions[] = {
	jump,
	jumpifnil,
	jumpiffalse,
	explode,
	implode,
	superimplode,
	add,
	sub,
	mul,
	div,
	rem,
	length,
	arrayindex,
	arrayslice,
	concat,
	booland,
	boolor,
	boolxor,
	inarray,
	strlike,
	// More functions WIP
};
const int function_count = sizeof(functions) / sizeof(Function);

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;

	Stack stack = {{1, 2, 3}, {1, 2, 3}};
	Context context = {stack, 0, {0, 0}, 0};
	context.stack.print();

	equal(context);
	context.stack.print();

	return 0;
}
