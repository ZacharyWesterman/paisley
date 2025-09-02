#include "trim.hpp"
#include <algorithm>

void trim(Context &context) noexcept
{
	auto values = std::get<std::vector<Value>>(context.stack.pop());
	auto text = values[0].to_string();
	auto chars = values[1].to_string();

	if (chars.empty())
	{
		// Trim whitespace from the beginning of the string
		text.erase(
			text.begin(),
			std::find_if(
				text.begin(), text.end(), [](unsigned char ch)
				{ return !std::isspace(ch); }));

		// Trim whitespace from the end of the string
		text.erase(
			std::find_if(
				text.rbegin(), text.rend(), [](unsigned char ch)
				{ return !std::isspace(ch); })
				.base(),
			text.end());

		context.stack.push(text);
		return;
	}

	// Remove any of a list of chars

	// Trim chars from the beginning of the string
	text.erase(
		text.begin(),
		std::find_if(text.begin(), text.end(), [chars](unsigned char ch)
					 { return chars.find(ch) == std::string::npos; }));

	// Trim chars from the end of the string
	text.erase(
		std::find_if(
			text.rbegin(), text.rend(), [chars](unsigned char ch)
			{ return chars.find(ch) == std::string::npos; })
			.base(),
		text.end());

	context.stack.push(text);
}
