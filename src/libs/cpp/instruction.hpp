#pragma once

struct Instruction
{
	unsigned char opcode;
	int line_no;
	int operand[2];
};
