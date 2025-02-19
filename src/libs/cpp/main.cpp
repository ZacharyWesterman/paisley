#include "stack.hpp"
#include "context.hpp"
#include "functions.hpp"

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;

	Stack stack = {6, 2};
	Context context = {stack, 0, {0, 0}};
	context.stack.print();

	mod(context);
	context.stack.print();

	return 0;
}
