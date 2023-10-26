BUILTIN_COMMANDS = {
	"time:number",
	"sleep:null",
	"print:string",
	"error:string",
	"systime:number",
	"sysdate:number",
}

local function _explode(cmdlist)
	if not cmdlist then return {} end

	local cmds, i = {}
	for i = 1, #cmdlist do
		local c = std.split(cmdlist[i], ':')
		if not c[2] then c[2] = 'any' end
		cmds[c[1]] = c[2]
	end
	return cmds
end

BUILTIN_COMMANDS = _explode(BUILTIN_COMMANDS)
ALLOWED_COMMANDS = _explode(ALLOWED_COMMANDS)
