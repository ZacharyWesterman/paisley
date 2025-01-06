BUILTIN_COMMANDS = {
	"time:number",
	"sleep:null",
	"print:null",
	"error:null",
	"systime:number",
	"sysdate:array[number]",
	--[[minify-delete]]
	--The following commands are only available in the CLI version of Paisley
	"stdin:string",
	"stdout:null",
	"stderr:null",
	"!:string",
	"?:boolean",
	--[[/minify-delete]]
}

--[[minify-delete]]
CMD_DESCRIPTION = {
	time = 'Returns a number representing the in-game time.',
	systime = 'Returns a number representing the system time (seconds since midnight).',
	sysdate = 'Returns a numeric array containing the system day, month, and year.',
	print = 'Send all arguments to the "print" output.',
	error = 'Send all arguments to the "error" output.',
	sleep = 'Pause script execution for the given amount of seconds.',
	--The following commands are only available in the CLI version of Paisley
	stdin = 'Read a line of text from stdin.',
	stdout = 'Write text to stdout, with no line ending.',
	stderr = 'Write text to stderr, with no line ending.',
	['?'] = 'Execute a unix command, capturing the output. Run with no params to output the result of the last command.',
	['!'] =
	'Execute a unix command, capturing the return value. Run with no params to output the result of the last command.',
}
--[[/minify-delete]]

local function _explode(cmdlist)
	if not cmdlist then return {} end

	local cmds = {}
	for i = 1, #cmdlist do
		local c = std.split(cmdlist[i], ':')
		if not c[2] then c[2] = 'any' end
		cmds[c[1]] = SIGNATURE(c[2])
	end
	return cmds
end

BUILTIN_COMMANDS = _explode(BUILTIN_COMMANDS)
ALLOWED_COMMANDS = _explode(ALLOWED_COMMANDS)

--[[minify-delete]]
if _G['RESTRICT_TO_PLASMA_BUILD'] then
	BUILTIN_COMMANDS['stdin'] = nil
	BUILTIN_COMMANDS['stdout'] = nil
	BUILTIN_COMMANDS['stderr'] = nil
	BUILTIN_COMMANDS['!'] = nil
	BUILTIN_COMMANDS['?'] = nil
end
--[[/minify-delete]]
