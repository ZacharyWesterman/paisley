require "lex"

for token in lex('let i = {3.123}') do
	print_token(token)
end
