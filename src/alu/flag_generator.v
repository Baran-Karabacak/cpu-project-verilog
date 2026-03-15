`timescale 1ns / 1ps


module flag_generator (
	input wire [7:0] alu_result, // Final 8-bit result from the ALU
	input wire alu_carry_out, // Raw carry_out from the adder
	input wire a7, // MSB of operand A (Bit 7)
	input wire b7, // MSB of operand B (Bit 7)
	input wire is_sub, // Control Signal: 0 for ADD, 1 for SUB
	output wire flag_zero, // (Z) 1 if result is exactly 00000000
	output wire flag_carry, // (C) 1 if unsigned addition overflowed
	output wire flag_negative, // (N) 1 if result is negative (MSB is 1)
	output wire flag_overflow // (V) 1 if signed arithmetic overflowed
);

	// Same with assign flag_zero = ~|alu_result;
	assign flag_zero = ~(alu_result[0] | alu_result[1] | alu_result[2] | alu_result[3] | 
	                         alu_result[4] | alu_result[5] | alu_result[6] | alu_result[7]);

    assign flag_carry = alu_carry_out;

    assign flag_negative = alu_result[7];

	// If subtracting, B's bits are inverted. B's MSB flips if is_sub is 1
    wire b_effective_sign = b7 ^ is_sub;

    // Overflow occurs ONLY IF:
    // (A and Effective B have the SAME sign) AND (Result has a DIFFERENT sign than A)
    // XNOR is Equality, XOR is Inequality
    assign flag_overflow = ~(a7 ^ b_effective_sign) & (a7 ^ alu_result[7]);
