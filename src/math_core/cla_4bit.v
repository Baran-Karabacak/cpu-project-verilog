`timescale 1ns / 1ps

// ============================================================================
// 4-Bit Carry Lookahead Adder with Group Generate/Propagate.
// ============================================================================
module cla_4bit (
    input  wire [3:0] nibble_a,        // 4-bit input operand A
    input  wire [3:0] nibble_b,        // 4-bit input operand B
    input  wire       carry_in,        // Initial carry input

    output wire [3:0] sum_out,         // 4-bit sum result

    output wire       group_generate,  // True if this 4-bit block natively generates a carry
    output wire       group_propagate  // True if this 4-bit block can pass an incoming carry
);

    // Bitwise Generate (G) and Propagate (P) Signals
    wire [3:0] gen_bits;
    wire [3:0] prop_bits;

    assign gen_bits  = nibble_a & nibble_b;
    assign prop_bits = nibble_a ^ nibble_b;

    // Internal Lookahead Carry Logic Tree
    // Flattens the carry chain into parallel AND/OR gates for maximum speed.
    wire local_c1, local_c2, local_c3;

    assign local_c1 = gen_bits[0] | (prop_bits[0] & carry_in);

    assign local_c2 = gen_bits[1] | 
                      (prop_bits[1] & gen_bits[0]) | 
                      (prop_bits[1] & prop_bits[0] & carry_in);

    assign local_c3 = gen_bits[2] | 
                      (prop_bits[2] & gen_bits[1]) | 
                      (prop_bits[2] & prop_bits[1] & gen_bits[0]) | 
                      (prop_bits[2] & prop_bits[1] & prop_bits[0] & carry_in);

    // Sum Calculation
    assign sum_out = prop_bits ^ {local_c3, local_c2, local_c1, carry_in};
    
    // Propagates only if ALL bits are willing to pass a carry.
    assign group_propagate = prop_bits[3] & prop_bits[2] & prop_bits[1] & prop_bits[0];

    // Generates a carry if ANY local bit combination forces a carry out.
    assign group_generate  = gen_bits[3] | 
                            (prop_bits[3] & gen_bits[2]) | 
                            (prop_bits[3] & prop_bits[2] & gen_bits[1]) | 
                            (prop_bits[3] & prop_bits[2] & prop_bits[1] & gen_bits[0]);

endmodule