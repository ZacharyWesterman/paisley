#include "stack.hpp"
#include "variables.hpp"
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

	Stack stack = {0, 1};
	Variables variables;
	std::mt19937_64 rng;
	rng.seed(std::random_device()());

	Context context = {stack, variables, rng, 0, {0, 0}, 0};

	context.stack.print();
	random_float(context);
	context.stack.print();

	return 0;
}
