#include "fromepoch.hpp"
#include <ctime>

void fromepoch(Context &context) noexcept
{
	auto timestamp = std::get<std::vector<Value>>(context.stack.pop())[0].to_number();
	time_t rawtime = static_cast<time_t>(timestamp);

	struct tm timeinfo;
	localtime_r(&rawtime, &timeinfo);

	const auto result = std::map<std::string, Value>{
		{"date",
		 std::vector<Value>{
			 timeinfo.tm_mday,
			 timeinfo.tm_mon + 1,
			 timeinfo.tm_year + 1900}},
		{"time",
		 std::vector<Value>{
			 timeinfo.tm_hour,
			 timeinfo.tm_min,
			 timeinfo.tm_sec}}};

	context.stack.push(result);
}
