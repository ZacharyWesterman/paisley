#pragma once
 
#include "functions/acos.hpp"
#include "functions/add.hpp"
#include "functions/arrayindex.hpp"
#include "functions/arrayslice.hpp"
#include "functions/asin.hpp"
#include "functions/atan2.hpp"
#include "functions/atan.hpp"
#include "functions/booland.hpp"
#include "functions/boolnot.hpp"
#include "functions/boolor.hpp"
#include "functions/boolxor.hpp"
#include "functions/ceil.hpp"
#include "functions/concat.hpp"
#include "functions/cos.hpp"
#include "functions/dist.hpp"
#include "functions/div.hpp"
#include "functions/equal.hpp"
#include "functions/explode.hpp"
#include "functions/floor.hpp"
#include "functions/greaterequal.hpp"
#include "functions/greater.hpp"
#include "functions/implode.hpp"
#include "functions/inarray.hpp"
#include "functions/jump.hpp"
#include "functions/jumpiffalse.hpp"
#include "functions/jumpifnil.hpp"
#include "functions/length.hpp"
#include "functions/lessequal.hpp"
#include "functions/less.hpp"
#include "functions/mul.hpp"
#include "functions/notequal.hpp"
#include "functions/random_float.hpp"
#include "functions/random_int.hpp"
#include "functions/rem.hpp"
#include "functions/round.hpp"
#include "functions/sin.hpp"
#include "functions/sqrt.hpp"
#include "functions/strlike.hpp"
#include "functions/sub.hpp"
#include "functions/superimplode.hpp"
#include "functions/tan.hpp"
#include "functions/varexists.hpp"
#include "functions/word_diff.hpp"

typedef void (*Function)(Context &);
const Function FUNCTIONS[] = {
	acos,
	add,
	arrayindex,
	arrayslice,
	asin,
	atan2,
	atan,
	booland,
	boolnot,
	boolor,
	boolxor,
	ceil,
	concat,
	cos,
	dist,
	div,
	equal,
	explode,
	floor,
	greaterequal,
	greater,
	implode,
	inarray,
	jump,
	jumpiffalse,
	jumpifnil,
	length,
	lessequal,
	less,
	mul,
	notequal,
	random_float,
	random_int,
	rem,
	round,
	sin,
	sqrt,
	strlike,
	sub,
	superimplode,
	tan,
	varexists,
	word_diff,
};
const int FUNCTION_COUNT = sizeof(FUNCTIONS) / sizeof(Function);
