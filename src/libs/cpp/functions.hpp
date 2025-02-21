#pragma once

#include "functions/abs.hpp"
#include "functions/acos.hpp"
#include "functions/add.hpp"
#include "functions/append.hpp"
#include "functions/arrayindex.hpp"
#include "functions/arrayslice.hpp"
#include "functions/asin.hpp"
#include "functions/atan2.hpp"
#include "functions/atan.hpp"
#include "functions/b64_decode.hpp"
#include "functions/b64_encode.hpp"
#include "functions/booland.hpp"
#include "functions/bool.hpp"
#include "functions/boolnot.hpp"
#include "functions/boolor.hpp"
#include "functions/boolxor.hpp"
#include "functions/camel.hpp"
#include "functions/ceil.hpp"
#include "functions/clocktime.hpp"
#include "functions/concat.hpp"
#include "functions/cos.hpp"
#include "functions/dist.hpp"
#include "functions/div.hpp"
#include "functions/equal.hpp"
#include "functions/explode.hpp"
#include "functions/floor.hpp"
#include "functions/greaterequal.hpp"
#include "functions/greater.hpp"
#include "functions/hex.hpp"
#include "functions/implode.hpp"
#include "functions/inarray.hpp"
#include "functions/index.hpp"
#include "functions/join.hpp"
#include "functions/json_decode.hpp"
#include "functions/json_encode.hpp"
#include "functions/json_valid.hpp"
#include "functions/jump.hpp"
#include "functions/jumpiffalse.hpp"
#include "functions/jumpifnil.hpp"
#include "functions/length.hpp"
#include "functions/lessequal.hpp"
#include "functions/less.hpp"
#include "functions/lower.hpp"
#include "functions/lpad.hpp"
#include "functions/matches.hpp"
#include "functions/match.hpp"
#include "functions/max.hpp"
#include "functions/min.hpp"
#include "functions/mul.hpp"
#include "functions/mult.hpp"
#include "functions/notequal.hpp"
#include "functions/num.hpp"
#include "functions/pow.hpp"
#include "functions/random_float.hpp"
#include "functions/random_int.hpp"
#include "functions/rem.hpp"
#include "functions/replace.hpp"
#include "functions/reverse.hpp"
#include "functions/round.hpp"
#include "functions/rpad.hpp"
#include "functions/sin.hpp"
#include "functions/sort.hpp"
#include "functions/split.hpp"
#include "functions/sqrt.hpp"
#include "functions/str.hpp"
#include "functions/strlike.hpp"
#include "functions/sub.hpp"
#include "functions/sum.hpp"
#include "functions/superimplode.hpp"
#include "functions/tan.hpp"
#include "functions/type.hpp"
#include "functions/upper.hpp"
#include "functions/varexists.hpp"
#include "functions/word_diff.hpp"

/*
typedef void (*Function)(Context &);
const Function FUNCTIONS[] = {
	jump,
	jumpifnil,
	jumpiffalse,
	explode,
	implode,
	superimplode,
	add,
	sub,
	mul,
	div,
	rem,
	length,
	arrayindex,
	arrayslice,
	concat,
	booland,
	boolor,
	boolxor,
	inarray,
	strlike,
	equal,
	notequal,
	greater,
	greaterequal,
	less,
	lessequal,
	boolnot,
	varexists,
	random_int,
	random_float,
	word_diff,
	dist,
	sin,
	cos,
	tan,
	asin,
	acos,
	atan,
	atan2,
	sqrt,
	sum,
	mult,
	pow,
	min,
	max,
	split,
	join,
	type,
	_bool,
	num,
	str,
	floor,
	ceil,
	round,
	abs,
	append,
	index,
	lower,
	upper,
	camel,
	replace,
	json_encode,
	json_decode,
	json_valid,
	b64_encode,
	b64_decode,
	lpad,
	rpad,
	hex,
	filter,
	matches,
	clocktime,
	reverse,
	sort,
	bytes,
	frombytes,
	merge,
	update,
	insert,
	_delete,
	lerp,
	random_element,
	hash,
	object,
	array,
	keys,
	values,
	pairs,
	interleave,
	unique,
	_union,
	intersection,
	difference,
	symmetric_difference,
	is_disjoint,
	is_subset,
	is_superset,
	count,
	find,
	flatten,
	smoothstep,
	sinh,
	cosh,
	tanh,
	sign,
	ascii,
	_char,
	beginswith,
	endswith,
	numeric_string,
	time,
	date,
	random_elements,
	match,
	splice,
};
const int FUNCTION_COUNT = sizeof(FUNCTIONS) / sizeof(Function);
*/
