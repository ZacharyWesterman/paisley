--Specify the numeric codes of all functions in the paisley runtime
--This lookup table is used instead of the function name, to reduce bytecode size.
CALL_CODES = {
	jump = 0,
	jumpifnil = 1,
	jumpiffalse = 2,
	explode = 3,
	implode = 4,
	superimplode = 5,
	add = 6,
	sub = 7,
	mul = 8,
	div = 9,
	rem = 10,
	length = 11,
	arrayindex = 12,
	arrayslice = 13,
	concat = 14,
	booland = 15,
	boolor = 16,
	boolxor = 17,
	inarray = 18,
	strlike = 19,
	equal = 20,
	notequal = 21,
	greater = 22,
	greaterequal = 23,
	less = 24,
	lessequal = 25,
	boolnot = 26,
	varexists = 27,
	random_int = 28,
	random_float = 29,
	word_diff = 30,
	dist = 31,
	sin = 32,
	cos = 33,
	tan = 34,
	asin = 35,
	acos = 36,
	atan = 37,
	atan2 = 38,
	sqrt = 39,
	sum = 40,
	mult = 41,
	pow = 42,
	min = 43,
	max = 44,
	split = 45,
	join = 46,
	type = 47,
	bool = 48,
	num = 49,
	str = 50,
	floor = 51,
	ceil = 52,
	round = 53,
	abs = 54,
	append = 55,
	index = 56,
	lower = 57,
	upper = 58,
	camel = 59,
	replace = 60,
	json_encode = 61,
	json_decode = 62,
	json_valid = 63,
	b64_encode = 64,
	b64_decode = 65,
	lpad = 66,
	rpad = 67,
	hex = 68,
	filter = 69,
	matches = 70,
	clocktime = 71,
	reverse = 72,
	sort = 73,
	bytes = 74,
	frombytes = 75,
	merge = 76,
	update = 77,
	insert = 78,
	delete = 79,
	lerp = 80,
	random_element = 81,
	hash = 82,
	object = 83,
	array = 84,
	keys = 85,
	values = 86,
	pairs = 87,
	interleave = 88,
	unique = 89,
	union = 90,
	intersection = 91,
	difference = 92,
	symmetric_difference = 93,
	is_disjoint = 94,
	is_subset = 95,
	is_superset = 96,
	count = 97,
	find = 98,
	flatten = 99,
	smoothstep = 100,
	sinh = 101,
	cosh = 102,
	tanh = 103,
	sign = 104,
	ascii = 105,
	char = 106,
	beginswith = 107,
	endswith = 108,
	numeric_string = 109,
	time = 110,
	date = 111,
	random_elements = 112,
	match = 113,
	splice = 114,
	uuid = 115,
	glob = 116,
	--[[minify-delete]]
	file_glob = 117,
	--[[/minify-delete]]
	xml_encode = 118,
	xml_decode = 119,
}
