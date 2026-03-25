`timescale 1ns / 1ps


// 16 bit incrementer
module inc_16bit (
    input wire [15:0] in_val,
    output wire [15:0] out_val
);

    wire [15:0] c; // Carry Chain

    assign out_val[0] = ~in_val[0];
    assign c[0]       = in_val[0];

    // Bit 1 - 15: Half-Adder Chain (Sum = A XOR Carry, Next_Carry = A AND Carry)
    assign out_val[1] = in_val[1] ^ c[0];
    assign c[1] = in_val[1] & c[0];

    assign out_val[2] = in_val[2] ^ c[1];
    assign c[2] = in_val[2] & c[1];

    assign out_val[3] = in_val[3] ^ c[2];
    assign c[3] = in_val[3] & c[2];

    assign out_val[4] = in_val[4] ^ c[3];
    assign c[4] = in_val[4] & c[3];

    assign out_val[5] = in_val[5] ^ c[4];
    assign c[5] = in_val[5] & c[4];

    assign out_val[6] = in_val[6] ^ c[5];
    assign c[6] = in_val[6] & c[5];

    assign out_val[7] = in_val[7] ^ c[6];
    assign c[7] = in_val[7] & c[6];

    assign out_val[8] = in_val[8] ^ c[7];
    assign c[8] = in_val[8] & c[7];

    assign out_val[9] = in_val[9] ^ c[8];
    assign c[9] = in_val[9] & c[8];

    assign out_val[10] = in_val[10] ^ c[9];
    assign c[10] = in_val[10] & c[9];

    assign out_val[11] = in_val[11] ^ c[10];
    assign c[11] = in_val[11] & c[10];

    assign out_val[12] = in_val[12] ^ c[11];
    assign c[12] = in_val[12] & c[11];

    assign out_val[13] = in_val[13] ^ c[12];
    assign c[13] = in_val[13] & c[12];

    assign out_val[14] = in_val[14] ^ c[13];
    assign c[14] = in_val[14] & c[13];

    // No need for last bit
    assign out_val[15] = in_val[15] ^ c[14];

endmodule