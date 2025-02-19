#include "stack.hpp"
#include "context.hpp"
#include "functions.hpp"

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;

	Stack stack = {1, {2, 3, 4}, 3};
	stack.print();

	stack.pop();
	stack.print();

	Context context = {stack, 0, {0, 0}};
	explode(context);
	stack.print();

	context.arg.x = 4; // Join 4 elements
	implode(context);
	stack.print();

	return 0;
}
