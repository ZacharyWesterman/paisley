return {
	theme = {
		type = 'var(--vscode-charts-green)',
		func = '#dcdcaa',
		var = '#9cdcfe',
		command = '#569cd6',
		sub = '#4ec9b0',
		keyword = '#c586c0',
	},

	color = function(text, color)
		return '<span style="color:' .. color .. ';">' .. text .. '</span>'
	end,
}
