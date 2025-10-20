program := statement+

statement :=
	| if_stmt
	| while_stmt
	| for_stmt
	| delete_stmt
	| subroutine
	| gosub_stmt
	| let_stmt
	| uncache_stmt
	| break_stmt
	| continue_stmt
	| return_stmt
	| match_stmt
	| alias_stmt
	| try_stmt
	| command

if_stmt :=
	| `if` argument `then` program? `end`
	| `if` argument `then` program? else_stmt
	| `if` argument else_stmt

else_stmt :=
	| `elif` program? `end`
	| `elif` program? else_stmt
	| `else` program? `end`

while_stmt :=
	| `while` argument `do` program? `end`

command := argument+
