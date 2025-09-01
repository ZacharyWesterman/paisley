#include "random_weighted.hpp"
#include <iostream>

void random_weighted(Context &context) noexcept
{
	auto args = std::get<std::vector<Value>>(context.stack.pop());
	auto array = args[0].to_array();
	auto weights = args[1].to_array();

	const auto length = std::min(array.size(), weights.size());

	// Calculate the total weight
	double total_weight = 0;
	for (const auto &weight : weights)
	{
		total_weight += weight.to_number();
	}

	double r = ((double)(context.rng() % RAND_MAX) / RAND_MAX) * total_weight;
	double cumulative = 0;

	for (size_t i = 0; i < length; i++)
	{
		cumulative += weights[i].to_number();
		std::cout << r << " " << cumulative << std::endl;
		if (r < cumulative)
		{
			context.stack.push(array[i]);
			return;
		}
	}

	context.stack.push(array.back());
}
