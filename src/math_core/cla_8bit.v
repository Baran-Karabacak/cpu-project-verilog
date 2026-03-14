`timescale 1ns / 1ps

// ============================================================================
// 8-Bit Hierarchical Carry Lookahead Adder.
// ============================================================================
module cla_8bit (
    input  wire [7:0] operand_a,  // 8-bit input A
    input  wire [7:0] operand_b,  // 8-bit input B
    input  wire       carry_in,   // Global carry input (e.g., from subtraction)
    output wire [7:0] sum_out,    // 8-bit sum result
    output wire       carry_out   // Global carry out (determines Carry Flag)
);

    // Group signals retrieved from the sub-modules
    wire group_gen_low,  group_prop_low;  // Signals from bits [3:0]
    wire group_gen_high, group_prop_high; // Signals from bits [7:4]

    // Internal lookahead carry across blocks
    wire lookahead_carry_mid;

    // Lower Nibble Block (Least Significant Bits: [3:0])
    cla_4bit lower_nibble (
        .nibble_a        (operand_a[3:0]),
        .nibble_b        (operand_b[3:0]),
        .carry_in        (carry_in),
        .sum_out         (sum_out[3:0]),
        .group_generate  (group_gen_low),
        .group_propagate (group_prop_low)
    );

    // Instantly predicts the carry for the upper block
    assign lookahead_carry_mid = group_gen_low | (group_prop_low & carry_in);

    // Upper Nibble Block (Most Significant Bits: [7:4])
    cla_4bit upper_nibble (
        .nibble_a        (operand_a[7:4]),
        .nibble_b        (operand_b[7:4]),
        .carry_in        (lookahead_carry_mid),
        .sum_out         (sum_out[7:4]),
        .group_generate  (group_gen_high),
        .group_propagate (group_prop_high)
    );

    // Final Global Carry Out Calculation
    assign carry_out = group_gen_high | 
                       (group_prop_high & group_gen_low) | 
                       (group_prop_high & group_prop_low & carry_in);

endmodule