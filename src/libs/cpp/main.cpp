#include "stack.hpp"
#include "context.hpp"
#include "functions.hpp"

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;

	Stack stack = {{1, 2, 3, 4, "abc", "def", "ghi"}};
	Context context = {stack, 0, {0, 0}};
	context.stack.print();

	context.stack.push("TEST");
	context.stack.print();

	length(context);
	context.stack.print();
	context.stack.pop();

	length(context);
	context.stack.print();

	return 0;
}
