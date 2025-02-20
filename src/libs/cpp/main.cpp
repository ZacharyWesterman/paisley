#include "stack.hpp"
#include "variables.hpp"
#include "context.hpp"
#include "functions.hpp"

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;

	Stack stack = {{"this is a test", " ", "_"}};
	Variables variables;
	std::mt19937_64 rng;
	rng.seed(std::random_device()());

	Context context = {stack, variables, rng, 0, {0, 0}, 0};

	context.stack.print();
	replace(context);
	context.stack.print();

	return 0;
}
