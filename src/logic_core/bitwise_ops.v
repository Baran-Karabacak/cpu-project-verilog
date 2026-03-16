`timescale 1ns / 1ps

module op_and(
    input  [7:0] in_B,
    input  [7:0] in_C,
    output [7:0] out_A
);
    assign out_A = in_B & in_C;
endmodule

module op_nor(
    input  [7:0] in_B,
    input  [7:0] in_C,
    output [7:0] out_A
);
    assign out_A = ~(in_B | in_C);
endmodule

module op_xor(
    input  [7:0] in_B,
    input  [7:0] in_C,
    output [7:0] out_A
);
    assign out_A = in_B ^ in_C;
endmodule

module op_rsh(
    input  [7:0] in_C,
    output [7:0] out_A
);
    assign out_A = {1'b0, in_B[7:1]};
endmodule


module op_nop(
    output [7:0] out_A
);
    assign out_A = 8'b00000000;
endmodule

module op_hlt(
    output [7:0] out_A
);
    assign out_A = 8'b00000000;
endmodule