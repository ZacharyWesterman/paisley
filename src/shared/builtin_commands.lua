BUILTIN_COMMANDS = {
	"time:number",
	"sleep:null",
	"print:null",
	"error:null",
	"systime:number",
	"sysdate:array[number]",
}

--[[minify-delete]]
CMD_DESCRIPTION = {
	time = 'Returns a number representing the in-game time.',
	systime = 'Returns a number representing the system time (seconds since midnight).',
	sysdate = 'Returns a numeric array containing the system day, month, and year.',
	print = 'Send all arguments to the "print" output.',
	error = 'Send all arguments to the "error" output.',
	sleep = 'Pause script execution for the given amount of seconds.',
}
--[[/minify-delete]]

local function _explode(cmdlist)
	if not cmdlist then return {} end

	local cmds = {}
	for i = 1, #cmdlist do
		local c = std.split(cmdlist[i], ':')
		if not c[2] then c[2] = 'any' end
		cmds[c[1]] = c[2]
	end
	return cmds
end

BUILTIN_COMMANDS = _explode(BUILTIN_COMMANDS)
ALLOWED_COMMANDS = _explode(ALLOWED_COMMANDS)
