ESCAPE_CODES = {
	['n'] = '\n',
	['t'] = '\t',
	['"'] = '"',
	['\''] = '\'',
	['\\'] = '\\',
	['r'] = '\r',
	[' '] = ' ', --non-breaking space
	['{'] = '{',
	['}'] = '}',
	['^-^'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=0>' --[[minify-delete]],
		default = '😌',
	} --[[/minify-delete]],
	[':relaxed:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=0>' --[[minify-delete]],
		default = '😌',
	} --[[/minify-delete]],
	[':P'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=1>' --[[minify-delete]],
		default = '😋',
	} --[[/minify-delete]],
	[':yum:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=1>' --[[minify-delete]],
		default = '😋',
	} --[[/minify-delete]],
	['<3'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=2>' --[[minify-delete]],
		default = '❤️',
	} --[[/minify-delete]],
	[':heart_eyes:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=2>' --[[minify-delete]],
		default = '❤️',
	} --[[/minify-delete]],
	['B)'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=3>' --[[minify-delete]],
		default = '😎',
	} --[[/minify-delete]],
	[':sunglasses:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=3>' --[[minify-delete]],
		default = '😎',
	} --[[/minify-delete]],
	[':D'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=4>' --[[minify-delete]],
		default = '😀',
	} --[[/minify-delete]],
	[':grinning:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=4>' --[[minify-delete]],
		default = '😀',
	} --[[/minify-delete]],
	['^o^'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=5>' --[[minify-delete]],
		default = '😄',
	} --[[/minify-delete]],
	[':smile:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=5>' --[[minify-delete]],
		default = '😄',
	} --[[/minify-delete]],
	['XD'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=6>' --[[minify-delete]],
		default = '😆',
	} --[[/minify-delete]],
	[':laughing:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=6>' --[[minify-delete]],
		default = '😆',
	} --[[/minify-delete]],
	[':lol:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=6>' --[[minify-delete]],
		default = '😆',
	} --[[/minify-delete]],
	['=D'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=7>' --[[minify-delete]],
		default = '😃',
	} --[[/minify-delete]],
	[':smiley:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=7>' --[[minify-delete]],
		default = '😃',
	} --[[/minify-delete]],
	[':sweat_smile:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=9>' --[[minify-delete]],
		default = '😅',
	} --[[/minify-delete]],
	['DX'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=10>' --[[minify-delete]],
		default = '😱',
	} --[[/minify-delete]],
	[':tired_face:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=10>' --[[minify-delete]],
		default = '😫',
	} --[[/minify-delete]],
	[';P'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=11>' --[[minify-delete]],
		default = '😜',
	} --[[/minify-delete]],
	[':stuck_out_tongue_winking_eye:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=11>' --[[minify-delete]],
		default = '😜',
	} --[[/minify-delete]],
	[':-*'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=12>' --[[minify-delete]],
		default = '😘',
	} --[[/minify-delete]],
	[';-*'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=12>' --[[minify-delete]],
		default = '😘',
	} --[[/minify-delete]],
	[':kissing_heart:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=12>' --[[minify-delete]],
		default = '😘',
	} --[[/minify-delete]],
	[':kissing:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=12>' --[[minify-delete]],
		default = '😘',
	} --[[/minify-delete]],
	[':rofl:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=13>' --[[minify-delete]],
		default = '🤣',
	} --[[/minify-delete]],
	[':)'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=14>' --[[minify-delete]],
		default = '🙂',
	} --[[/minify-delete]],
	[':slight_smile:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=14>' --[[minify-delete]],
		default = '🙂',
	} --[[/minify-delete]],
	[':('] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=15>' --[[minify-delete]],
		default = '🙁',
	} --[[/minify-delete]],
	[':frown:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=15>' --[[minify-delete]],
		default = '🙁',
	} --[[/minify-delete]],
	[':frowning:'] = --[[minify-delete]] {
		plasma = --[[/minify-delete]] '<sprite=15>' --[[minify-delete]],
		default = '🙁',
	} --[[/minify-delete]],
	['x'] = {
		next = '%x%x',
		op = function(next)
			--convert 2 hex digits to a character
			return string.char(tonumber(next, 16))
		end,
	},
}
