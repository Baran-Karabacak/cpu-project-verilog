`timescale 1ps/1ps

module alu(
    input [2:0] parsed_opcode,
    input [7:0] in_B, in_C,
    output [7:0] out_A,
    output flag_zero, flag_carry, flag_negative, flag_overflow
);
    // Constants
    wire wire_zero = 1b'0;
    wire wire_one  = 1b'1;
    // Module result carriers
    wire [7:0] out_nop, out_hlt, out_add, out_sub,
    wire [7:0] out_nor, out_and, out_xor, out_rsh,
    wire [7:0] out_mux
    wire carry_add, carry_sub;
 
    op_nop (out_A);
    op_hlt (out_A);
    op_nor (in_B, in_C, out_A); //FLAG
    op_and (in_B, in_C, out_A); //FLAG
    op_xor (in_B, in_C, out_A); //FLAG
    op_rsh (in_C, out_A);

    add_sub_8bit op_add (
        .operand_a(in_B),
        .operand_b(in_C),
        .is_sub(1b'0),
        .result(out_add),
        .carry_out(carry_add)
    ); //FLAG
    add_sub_8bit op_sub (
        .operand_a(in_B),
        .operand_b(in_C),
        .is_sub(1b'1),
        .result(out_sub),
        .carry_out(carry_sub)
    ); //FLAG

    mux_8to1_8bit result (
        .S(parsed_opcode),
	    .in_nop(out_nop), 
        .in_hlt(out_hlt), 
        .in_add(out_add), 
        .in_sub(out_sub), 
        .in_nor(out_nor), 
        .in_and(out_and), 
        .in_xor(out_xor), 
        .in_rsh(out_rsh), // 8bits outputs
	    .Z(out_mux)
    );
endmodule