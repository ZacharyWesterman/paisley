#include "toepoch.hpp"
#include <ctime>

void toepoch(Context &context) noexcept
{
	auto datetime = std::get<std::vector<Value>>(context.stack.pop())[0].to_object();
	const auto dateobj = datetime["date"].to_array();
	const auto timeobj = datetime["time"].to_array();

	const int year = (dateobj.size() > 2) ? dateobj[2].to_number() : 1970;
	const int month = (dateobj.size() > 1) ? dateobj[1].to_number() : 1;
	const int day = (dateobj.size() > 0) ? dateobj[0].to_number() : 1;
	const int hour = (timeobj.size() > 0) ? timeobj[0].to_number() : 0;
	const int minute = (timeobj.size() > 1) ? timeobj[1].to_number() : 0;
	const int second = (timeobj.size() > 2) ? timeobj[2].to_number() : 0;

	time_t rawtime;
	struct tm timeinfo;
	time(&rawtime);
	timeinfo = *localtime(&rawtime);

	timeinfo.tm_year = year - 1900;
	timeinfo.tm_mon = month - 1;
	timeinfo.tm_mday = day;
	timeinfo.tm_hour = hour;
	timeinfo.tm_min = minute;
	timeinfo.tm_sec = second;

	const auto date = mktime(&timeinfo);
	context.stack.push(date);
}
