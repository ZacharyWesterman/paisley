BUILTIN_COMMANDS = {
	"time:number",
	"sleep:null",
	"print:null",
	"error:null",
	"systime:number",
	"sysdate:array[number]",
	--[[minify-delete]]
	--The following commands are only available in the CLI version of Paisley
	"clear:null",
	"stdin:string",
	"stdout:null",
	"stderr:null",
	"=:boolean",
	"?:string",
	"!:string",
	"?!:string",
	--[[/minify-delete]]
}

--[[minify-delete]]
CMD_DESCRIPTION = {
	time = 'Returns a number representing the in-game time.',
	systime = 'Returns a number representing the system time (seconds since midnight).',
	sysdate = 'Returns a numeric array containing the system day, month, and year.',
	print = 'Send all arguments to the "print" output.',
	error = 'Raise an exception with the given text.',
	sleep = 'Pause script execution for the given amount of seconds.',
	--The following commands are only available in the CLI version of Paisley
	clear = 'Clear the screen if the terminal supports it.',
	stdin = 'Read a line of text from stdin.',
	stdout = 'Write text to stdout, with no line ending.',
	stderr = 'Write text to stderr, with no line ending.',
	['='] =
	'Execute a unix command, capturing the return value. Run with no params to output the result of the last command.',
	['?'] =
	'Execute a unix command, capturing the stdout output. Run with no params to output the result of the last command.',
	['!'] =
	'Execute a unix command, capturing the stderr output. Run with no params to output the result of the last command.',
	['?!'] =
	'Execute a unix command, capturing both the stdout and stderr output. Run with no params to output the result of the last command.',
}
--[[/minify-delete]]

local function _explode(cmdlist)
	if not cmdlist then return {} end

	local cmds = {}
	for i = 1, #cmdlist do
		local c = std.split(cmdlist[i], ':')
		if not c[2] then c[2] = 'any' end
		cmds[c[1]] = SIGNATURE(c[2])
		--[[minify-delete]]
		if c[3] and not CMD_DESCRIPTION[c[1]] then CMD_DESCRIPTION[c[1]] = c[3] end
		--[[/minify-delete]]
	end
	return cmds
end

BUILTIN_COMMANDS = _explode(BUILTIN_COMMANDS)
ALLOWED_COMMANDS = _explode(ALLOWED_COMMANDS)

--[[minify-delete]]
function PLASMA_RESTRICT()
	RESTRICT_TO_PLASMA_BUILD = true
	BUILTIN_COMMANDS['clear'] = nil
	BUILTIN_COMMANDS['stdin'] = nil
	BUILTIN_COMMANDS['stdout'] = nil
	BUILTIN_COMMANDS['stderr'] = nil
	SHELL_RESTRICT()
end

function SHELL_RESTRICT()
	BUILTIN_COMMANDS['='] = nil
	BUILTIN_COMMANDS['?'] = nil
	BUILTIN_COMMANDS['!'] = nil
	BUILTIN_COMMANDS['?!'] = nil
end

if _G['RESTRICT_TO_PLASMA_BUILD'] then
	PLASMA_RESTRICT()
end

if _G['SANDBOX'] then
	SHELL_RESTRICT()
end
--[[/minify-delete]]
