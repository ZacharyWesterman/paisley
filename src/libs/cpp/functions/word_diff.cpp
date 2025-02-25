#include "word_diff.hpp"

int levenschtein(const std::string &word1, const std::string &word2, int max) noexcept
{
	const int len1 = word1.length();
	const int len2 = word2.length();

	auto row0 = new int[len2 + 1];
	auto row1 = new int[len2 + 1];

	for (int i = 0; i <= len2; ++i)
	{
		row0[i] = i;
	}

	for (int i = 0; i <= len1 - 1; ++i)
	{
		row1[0] = i + 1;

		for (int j = 0; j <= len2 - 1; ++j)
		{
			auto deletionCost = row0[j + 1] + 1; /*NOLINT*/
			auto insertionCost = row1[j] + 1;
			auto substitutionCost = row0[j] + (word1[i] != word2[j]);

			row1[j + 1] = std::min(std::min(deletionCost, insertionCost), substitutionCost);

			/*If the current distance is greater than the max, just exit*/
			if (row1[j + 1] - 2 > max)
			{
				delete[] row0;
				delete[] row1;
				return std::numeric_limits<int>::max();
			}
		}

		/*Swap rows*/
		auto temp = row0;
		row0 = row1;
		row1 = temp;
	}

	auto result = row0[len2];
	delete[] row0;
	delete[] row1;
	return result;
}

void word_diff(Context &context) noexcept
{
	auto params = std::get<std::vector<Value>>(context.stack.pop());
	auto word1 = params[0].to_string();
	auto word2 = params[1].to_string();

	context.stack.push(levenschtein(word1, word2, 1000));
}
