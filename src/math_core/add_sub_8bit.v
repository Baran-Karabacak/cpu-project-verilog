`timescale 1ns / 1ps

module add_sub_8bit (
	input wire [7:0] operand_a,	// 8-bit input A
	input wire [7:0] operand_b,	// 8-bit input B
	input wire is_sub, // Control Signal: 0 for ADD, 1 for SUB
	output wire [7:0] result, // 8-bit output result
	output wire carry_out
);

	// If is_sub = 1: XOR flips all bits of B (One's Complement).
    // If is_sub = 0: XOR passes all bits of B unchanged.
    // Note: {8{is_sub}} physically wires the 1-bit signal to 8 parallel XOR gates.
	wire [7:0] b_modified;

	// There is no performance difference between this and one line version; I just wanted to do it like this.
	assign b_modified[0] = operand_b[0] ^ is_sub;
	assign b_modified[1] = operand_b[1] ^ is_sub;
    assign b_modified[2] = operand_b[2] ^ is_sub;
    assign b_modified[3] = operand_b[3] ^ is_sub;
    assign b_modified[4] = operand_b[4] ^ is_sub;
    assign b_modified[5] = operand_b[5] ^ is_sub;
    assign b_modified[6] = operand_b[6] ^ is_sub;
    assign b_modified[7] = operand_b[7] ^ is_sub;

    // The is_sub signal acts as the crucial "+ 1" for Two's Complement
    // by feeding directly into the carry_in port of adder
    cla_8bit math_engine (
    	.operand_a (operand_a),
    	.operand_b (b_modified),
    	.carry_in (is_sub),
    	.sum_out (result),
    	.carry_out (carry_out)	
    );

endmodule
