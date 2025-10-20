program :=
	| statement*

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
	| `if` argument `then` program `end`
	| `if` argument `then` program else_stmt
	| `if` argument `then` program elif_stmt
	| `if` argument else_stmt

elif_stmt :=
	| `elif` program `end`
	| `elif` program elif_stmt
	| `elif` program else_stmt

else_stmt :=
	| `else` program `end`

while_stmt :=
	| `while` argument `do` program `end`

for_stmt :=
	| `for` text+ `in` argument+ `do` program `end`

delete_stmt :=
	| `delete` text+

subroutine :=
	| `subroutine` text program `end`

gosub_stmt :=
	| `gosub` text

let_stmt :=
	| `let` variable `{` `}` `=` argument+
	| `let` variable `{` expression `}` `=` argument+
	| `let` variable+ `=` argument+
	| `let` variable+
	| `initial` variable `=` argument+

uncache_stmt :=
	| `break` `cache` text

break_stmt :=
	| `break` argument?

continue_stmt :=
	| `continue` argument?

return_stmt :=
	| `return` argument?

match_stmt :=
	| `match` argument `do` match_if_stmt+ `end`
	| `match` argument `do` match_if_stmt+ else_smt

match_if_stmt :=
	| `if` argument `then` program `end`

alias_stmt :=
	| `using` argument `as` argument
	| `using` argument

try_stmt :=
	| `try` program `catch` text? program `end`

command :=
	| argument+

argument :=
	| text
	| `{` expression `}`
	| `"` argument* `"`
	| `"""` argument* `"""`
	| `'` text? `'`
	| `'''` text? `'''`
	| `${` inline_command `}`

inline_command :=
	| gosub_stmt
	| command

