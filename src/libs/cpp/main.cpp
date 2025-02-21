#include "stack.hpp"
#include "variables.hpp"
#include "context.hpp"
#include "functions.hpp"

int main(int argc, char *argv[])
{
	(void)argc;
	(void)argv;

	// auto obj = std::map<std::string, Value>{{"a", 1}, {"b", 2}, {"d", Value({1, 2, 3})}, {"c", 3}};

	Stack stack = {{{3, 1, 4, 2, 5}}};
	Variables variables;
	std::mt19937_64 rng;
	rng.seed(std::random_device()());

	Context context = {stack, variables, rng, 0, {0, 0}, 0};

	context.stack.print();
	sort(context);
	context.stack.print();

	return 0;
}
