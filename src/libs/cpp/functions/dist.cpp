#include "dist.hpp"

void dist(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto point1 = params[0].to_array();
	auto point2 = params[1].to_array();

	// Get the euclidean distance between two points of any dimension.
	// If the points have different dimensions, the lesser dimension is used.
	double total = 0;
	for (size_t i = 0; i < std::min(point1.size(), point2.size()); i++)
	{
		double diff = point1[i].to_number() - point2[i].to_number();
		total += diff * diff;
	}
	context.stack.push(sqrt(total));
}
