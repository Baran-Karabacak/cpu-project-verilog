`timescale 1ns/1ps
// This multiplexer is a tool for a basic ALU. 
// The instructions are ADD, SUB, NOR, AND, XOR, RSH (There are more but we will use this muc in this version)
// Each instructions are half a word. The selected subset only operatos on r-type instructions
// Length of each field is 4 bits: OPCODE, REGA, REGB, REGC. Each instructions in this subset uses flags 
module mux_8to1_8bit(
	input [2:0] S,
	input [7:0] in_nop, in_hlt, in_add, in_sub, in_nor, in_and, in_xor, in_rsh, // 8bits outputs
	output [7:0] Z
);
// NOP: 0000 HLT: 0001 ADD: 0010, SUB: 0011, NOR: 0100, AND: 0101, XOR: 0110, RSH: 0111

	wire s2_not = ~S[2];
	wire s1_not = ~S[1];
	wire s0_not = ~S[0];

	// 1 Bit inputs for S. Codes are given in each comment line
	wire sel_nop = s2_not & s1_not & s0_not; // 000 -> s1' s2' s3'
	wire sel_hlt = s2_not & s1_not & S[0];   // 001 -> s1' s2' s3
	wire sel_add = s2_not & S[1] & s0_not;   // 010 -> s1' s2  s3'
	wire sel_sub = s2_not & S[1] & S[0];     // 011 -> s1' s2  s3
	wire sel_nor = S[2] & s1_not & s0_not;   // 100 -> s1  s2' s3'
	wire sel_and = S[2] & s1_not & S[0];     // 101 -> s1  s2' s3
	wire sel_xor = S[2] & S[1] & s0_not;     // 110 -> s1  s2  s3'
	wire sel_rsh = S[2] & S[1] & S[0];       // 111 -> s1  s2  s3

	// 110->s1s2s3' //111->s1s2s3
	assign Z = ({8{sel_nop}} & in_nop) |
			   ({8{sel_hlt}} & in_hlt) |
			   ({8{sel_add}} & in_add) |
	           ({8{sel_sub}} & in_sub) |
	           ({8{sel_nor}} & in_nor) |
	           ({8{sel_and}} & in_and) |
               ({8{sel_xor}} & in_xor) |
	           ({8{sel_rsh}} & in_rsh);
	
endmodule
