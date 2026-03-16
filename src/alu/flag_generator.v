`timescale 1ns / 1ps

module flag_generator (
    input wire [7:0] alu_result,    // Final 8-bit result from the ALU
    input wire       alu_carry_out, // Raw carry_out from the adder
    input wire       a7,            // MSB of operand A (Bit 7)
    input wire       b7,            // MSB of operand B (Bit 7)
    input wire       is_sub,        // Control Signal: 0 for ADD, 1 for SUB
    input wire       is_arithmetic, // 1 for Math, 0 for Logic
    output wire      flag_zero,     // (Z) 1 if result is exactly 00000000
    output wire      flag_carry,    // (C) 1 if unsigned addition overflowed
    output wire      flag_negative, // (N) 1 if result is negative (MSB is 1)
    output wire      flag_overflow  // (V) 1 if signed arithmetic overflowed
);

    // (Z): NOR gate equivalent for all bits
    assign flag_zero = ~(alu_result[0] | alu_result[1] | alu_result[2] | alu_result[3] | 
                         alu_result[4] | alu_result[5] | alu_result[6] | alu_result[7]);

    // (N): MSB directly dictates the negative status
    assign flag_negative = alu_result[7];

    // (C): Masked carry for arithmetic operations only
    assign flag_carry = alu_carry_out & is_arithmetic;

    // (V): Calculate raw overflow, then mask it
    wire b_effective_sign = b7 ^ is_sub;
    wire raw_overflow     = ~(a7 ^ b_effective_sign) & (a7 ^ alu_result[7]);
    
    assign flag_overflow  = raw_overflow & is_arithmetic;

endmodule