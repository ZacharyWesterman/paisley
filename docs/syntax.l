program :=
	| statement*

statement :=
	| if_stmt
	| while_stmt
	| for_stmt
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
	| delete_stmt
	| stop_stmt
	| import_stmt
	| command

if_stmt :=
	| `if` (argument|gosub_stmt) `then` program `end`
	| `if` (argument|gosub_stmt) `then` program else_stmt
	| `if` (argument|gosub_stmt) `then` program elif_stmt
	| `if` (argument|gosub_stmt) else_stmt

elif_stmt :=
	| `elif` program `end`
	| `elif` program elif_stmt
	| `elif` program else_stmt

else_stmt :=
	| `else` program `end`

while_stmt :=
	| `while` argument `do` program `end`

for_stmt :=
	| `for` <text>+ `in` argument+ `do` program `end`

delete_stmt :=
	| `delete` <text>+

subroutine :=
	| `subroutine` <text> program `end`

gosub_stmt :=
	| `gosub` <text>

let_stmt :=
	| `let` <variable> `{` `}` `=` argument+
	| `let` <variable> `{` expression `}` `=` argument+
	| `let` <variable>+ `=` argument+
	| `let` <variable>+
	| `initial` <variable> `=` argument+

uncache_stmt :=
	| `break` `cache` <text>

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
	| `if` match_argument `then` program `end`

match_argument :=
	| <text>
	| string
	| `{` (`>`|`<`|`>=`|`<=`|`=`|`!=`|`not`? `like`|`not`? `in`|`and`|`or`|`xor`) expression `}`
	| `{` expression `}`
	| `${` inline_command `}`

alias_stmt :=
	| `using` argument `as` argument
	| `using` argument

try_stmt :=
	| `try` program `catch` <text>? program `end`

stop_stmt :=
	| `stop`

import_stmt :=
	| `require` text+

command :=
	| (argument | pipeio)+

argument :=
	| <text>
	| string
	| `{` expression `}`
	| `${` inline_command `}`

pipeio :=
	| `|` command
	| stdio `>` (stdio | <text>)
	| `<` argument
	| `<<<` argument

stdio :=
	| `?`
	| `!`
	| `?!`

inline_command :=
	| gosub_stmt
	| command

expression :=
	| array

array :=
	| kv_pair `,` array
	| kv_pair `,`
	| kv_pair
	| `,`

kv_pair :=
	| ternary `=>` ternary
	| ternary
	| `=>`

ternary :=
	| list_comprehension `else` ternary
	| list_comprehension `if` list_comprehension `else` ternary
	| list_comprehension

list_comprehension :=
	| boolean `for` <variable> `in` list_comprehension `if` list_comprehension
	| boolean `for` <variable> `in` list_comprehension
	| boolean

boolean :=
	| `not` boolean
	| concat `and` boolean
	| concat `or` boolean
	| concat `xor` boolean
	| concat `exists`
	| concat

concat :=
	| comparison+

comparison :=
	| add `>` comparison
	| add `<` comparison
	| add `>=` comparison
	| add `<=` comparison
	| add `=` comparison
	| add `!=` comparison
	| add `in` comparison
	| add `like` comparison
	| add `not` `in` comparison
	| add `not` `like` comparison
	| add

add :=
	| mult `+` add
	| mult `-` add
	| mult

mult :=
	| slice `*` mult
	| slice `/` mult
	| slice `//` mult
	| slice `%` mult
	| slice

slice :=
	| negate `:` `:`
	| negate `:` slice
	| negate

negate :=
	| `-` negate
	| exponent

exponent :=
	| length `^` exponent
	| length

length :=
	| `&` dot_and_index
	| dot_and_index

dot_and_index :=
	| value (`.` value | `[` expression `]`)+
	| value

value :=
	| macro
	| func_call
	| <variable>
	| <number>
	| string
	| `true` | `false` | `null`
	| `(` expression `)`
	| `{` expression `}`
	| `${` inline_command `}`

macro :=
	| <exclamation> `[` expression `]`
	| <exclamation>

func_call :=
	| <variable> `(` expression `)`

string :=
	| `"` string_interp* `"`
	| `"""` string_interp* `"""`
	| `'` <text>? `'`
	| `'''` <text>? `'''`

string_interp :=
	| <text>
	| `{` expression `}`
	| `${` inline_command `}`
