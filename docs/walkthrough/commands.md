## Commands

### Inline Command Evaluation
Since commands can return values to Paisley after execution, you can also use those values in further calculations. For example:
```
#Get an integer value representing in-game time, and convert it to a human-readable format
let t = {floor(${time})}
let hour = {t // 3600}
let minute = {(t // 60) % 60}
let second = {t % 60}
print {hour ":" minute ":" second}
```
Of course, there is also a simpler version that does the same thing:
```
print {${time}.clocktime()[1:3].join(":")}
```

### Built-in commands
For ease of use and consistency, there are 7 built-in commands that will always be the same regardless of what the target environment is.
- `time`: Returns a number representing the clock time. If in a game engine, this is the in-game time. If on PC, this is the same as `systime`. Arguments are ignored.
- `systime`: Returns a number representing the system time (seconds since midnight). Arguments are ignored.
- `sysdate`: Returns a numeric array containing the system day, month, and year (in that order). Arguments are ignored.
- `print`: Prints any params to the 'print' or 'stdout' output.
- `error`: Raises an exception with the line number, message, and stack info. If not caught, outputs the error and ends the program.
- `sleep`: Pause script execution for the given amount of seconds. If the first argument is not a positive number, delay defaults to minimum value (0.02s).
- `.`: No-op. Calculates the value of its arguments and discards the result. Returns null.

In the PC build, the following commands are also available:
- `clear`: Clears the screen.
- `stdin`: Reads a line of text from stdin.
- `stdout`: Prints text to stdout, without a line ending.
- `stderr`: Prints text to stderr, without a line ending.
- `=`: Executes a unix command, capturing the return value. Run with no params to output the result of the last command.
- `?`: Executes a unix command, capturing the stdout output. Run with no params to output the result of the last command.
- `!`: Executes a unix command, capturing the stderr output. Run with no params to output the result of the last command.
- `?!`: Executes a unix command, capturing both the stdout and stderr output. Run with no params to output the result of the last command.

### Shell command coersion
If the `--shell` or `-l` flag is passed, then Paisley will assume that any undefined commands are programs available on this system.
```
# Plain commands will not capture stdout or stderr, so the following are equivalent:
wget https://127.0.0.1/example
= wget https://127.0.0.1/example

# But inline command evaluation captures stdout, so the following are equivalent:
let x = ${wget https://127.0.0.1/example}
let x = ${? wget https://127.0.0.1/example}
# And NOT equivalent to the following which captures the RETURN value of wget:
let x = ${= wget https://127.0.0.1/example}
```

### Command piping

Like Bash, the stdout of commands can be piped into other commands, or from and to files. This uses the same syntax as bash, for familiarity, and because the syntax is simple enough.
```
echo "some text" > my_file.txt
cat my_file.txt | grep "some"
grep "something <<<"text input"
grep "something" <"file input"
```
There is one difference however, and it's that the stdout and stderr files are not called `1` and `2` respectively, instead they are `?` and `!` to remain consistent with other syntax. For example, to pipe stderr into a file:
```
wget https://127.0.0.1/example !>my_file.txt
```
Also note that unlike in Bash, you must explicitly specify the input stream:
```
echo "text" >file.txt #This will not work!

echo "text" ?>file.text #Pipes stdout into the file.
echo "text" !>file.text #Pipes stderr into the file.
echo "text" ?!>file.text #Pipes BOTH stdout and stderr into the file.
echo "text" !>? #Pipes stderr to stdout.
```

---

### [< Prev][prev] | [Home](../walkthrough.md) | [Next >][next]

[prev]: [list_comprehension.md]
[next]: [comments.md]
