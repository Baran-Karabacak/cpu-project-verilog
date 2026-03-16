`timescale 1ps/1ps

module alu(
    input [2:0] parsed_opcode,
    input [7:0] in_B, in_C,
    output [7:0] out_A,
    output carry_add, carry_sub
);
    // Constants
    wire wire_zero = 1'b0;
    wire wire_one  = 1'b1;
    // Module result carriers
    wire [7:0] out_nop, out_hlt, out_add, out_sub;
    wire [7:0] out_nor, out_and, out_xor, out_rsh;
 
    op_nop ins_nop (out_nop);
    op_hlt ins_hlt (out_hlt);
    op_nor ins_nor (in_B, in_C, out_nor); //FLAG
    op_and ins_and (in_B, in_C, out_and); //FLAG
    op_xor ins_xor (in_B, in_C, out_xor); //FLAG
    op_rsh ins_rsh (in_C, out_rsh);

    add_sub_8bit op_add (
        .operand_a(in_B),
        .operand_b(in_C),
        .is_sub(1'b0),
        .result(out_add),
        .carry_out(carry_add)
    ); //FLAG
    add_sub_8bit op_sub (
        .operand_a(in_B),
        .operand_b(in_C),
        .is_sub(1'b1),
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
	    .Z(out_A)
    );
endmodule