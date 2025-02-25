#include "hex.hpp"

#include <iomanip>
#include <sstream>

void hex(Context &context) noexcept
{
	// Convert a number to a hexadecimal string
	auto params = std::get<std::vector<Value>>(context.stack.pop());

	auto num = params[0].to_number();
	auto len = params[1].to_number();

	std::stringstream ss;
	ss << std::hex << std::setw(len) << std::setfill('0') << static_cast<int>(num);

	context.stack.push(ss.str());
}
