`timescale 1ns / 1ps

module hardware_stack (
    input wire clk,
    input wire rst,
    input wire push,            // 1 if CAL
    input wire pop,             // 1 if RET
    input wire [15:0] data_in,  // Return Address (PC + 1)
    output wire [15:0] data_out // Stored Address
);


    // --- Stack Pointer (SP) ---
    wire [3:0] sp_out;
    wire [3:0] sp_plus_1  = sp_out + 4'b0001;
    wire [3:0] sp_minus_1 = sp_out - 4'b0001;

    wire sp_we = push | pop;

    // SP Multiplexer
    wire [3:0] sp_next = ({4{push}} & sp_plus_1) | 
                         ({4{pop & ~push}} & sp_minus_1);

    // 4-bit SP Register
    cpu_register #(.WIDTH(4)) sp_reg (
        .clk(clk),
        .rst(rst),
        .we(sp_we),
        .data_in(sp_next),
        .data_out(sp_out)
    );

    // --- 16x16-bit Registers ---
    wire [15:0] out_00, out_01, out_02, out_03, out_04, out_05, out_06, out_07;
    wire [15:0] out_08, out_09, out_0A, out_0B, out_0C, out_0D, out_0E, out_0F;

    // --- 4-to-16 DEMUX ---
    // Enables writing only on PUSH signal
    wire we_00 = push & ~|(sp_out ^ 4'h0);
    wire we_01 = push & ~|(sp_out ^ 4'h1);
    wire we_02 = push & ~|(sp_out ^ 4'h2);
    wire we_03 = push & ~|(sp_out ^ 4'h3);
    wire we_04 = push & ~|(sp_out ^ 4'h4);
    wire we_05 = push & ~|(sp_out ^ 4'h5);
    wire we_06 = push & ~|(sp_out ^ 4'h6);
    wire we_07 = push & ~|(sp_out ^ 4'h7);
    wire we_08 = push & ~|(sp_out ^ 4'h8);
    wire we_09 = push & ~|(sp_out ^ 4'h9);
    wire we_0A = push & ~|(sp_out ^ 4'hA);
    wire we_0B = push & ~|(sp_out ^ 4'hB);
    wire we_0C = push & ~|(sp_out ^ 4'hC);
    wire we_0D = push & ~|(sp_out ^ 4'hD);
    wire we_0E = push & ~|(sp_out ^ 4'hE);
    wire we_0F = push & ~|(sp_out ^ 4'hF);

    cpu_register #(.WIDTH(16)) cell_00 (.clk(clk), .rst(rst), .we(we_00), .data_in(data_in), .data_out(out_00));
    cpu_register #(.WIDTH(16)) cell_01 (.clk(clk), .rst(rst), .we(we_01), .data_in(data_in), .data_out(out_01));
    cpu_register #(.WIDTH(16)) cell_02 (.clk(clk), .rst(rst), .we(we_02), .data_in(data_in), .data_out(out_02));
    cpu_register #(.WIDTH(16)) cell_03 (.clk(clk), .rst(rst), .we(we_03), .data_in(data_in), .data_out(out_03));
    cpu_register #(.WIDTH(16)) cell_04 (.clk(clk), .rst(rst), .we(we_04), .data_in(data_in), .data_out(out_04));
    cpu_register #(.WIDTH(16)) cell_05 (.clk(clk), .rst(rst), .we(we_05), .data_in(data_in), .data_out(out_05));
    cpu_register #(.WIDTH(16)) cell_06 (.clk(clk), .rst(rst), .we(we_06), .data_in(data_in), .data_out(out_06));
    cpu_register #(.WIDTH(16)) cell_07 (.clk(clk), .rst(rst), .we(we_07), .data_in(data_in), .data_out(out_07));
    cpu_register #(.WIDTH(16)) cell_08 (.clk(clk), .rst(rst), .we(we_08), .data_in(data_in), .data_out(out_08));
    cpu_register #(.WIDTH(16)) cell_09 (.clk(clk), .rst(rst), .we(we_09), .data_in(data_in), .data_out(out_09));
    cpu_register #(.WIDTH(16)) cell_0A (.clk(clk), .rst(rst), .we(we_0A), .data_in(data_in), .data_out(out_0A));
    cpu_register #(.WIDTH(16)) cell_0B (.clk(clk), .rst(rst), .we(we_0B), .data_in(data_in), .data_out(out_0B));
    cpu_register #(.WIDTH(16)) cell_0C (.clk(clk), .rst(rst), .we(we_0C), .data_in(data_in), .data_out(out_0C));
    cpu_register #(.WIDTH(16)) cell_0D (.clk(clk), .rst(rst), .we(we_0D), .data_in(data_in), .data_out(out_0D));
    cpu_register #(.WIDTH(16)) cell_0E (.clk(clk), .rst(rst), .we(we_0E), .data_in(data_in), .data_out(out_0E));
    cpu_register #(.WIDTH(16)) cell_0F (.clk(clk), .rst(rst), .we(we_0F), .data_in(data_in), .data_out(out_0F));

    // --- 16-to-1 MUX ---
    wire [3:0] read_addr = sp_minus_1;

    assign data_out =
        ({16{~|(read_addr ^ 4'h0)}} & out_00) |
        ({16{~|(read_addr ^ 4'h1)}} & out_01) |
        ({16{~|(read_addr ^ 4'h2)}} & out_02) |
        ({16{~|(read_addr ^ 4'h3)}} & out_03) |
        ({16{~|(read_addr ^ 4'h4)}} & out_04) |
        ({16{~|(read_addr ^ 4'h5)}} & out_05) |
        ({16{~|(read_addr ^ 4'h6)}} & out_06) |
        ({16{~|(read_addr ^ 4'h7)}} & out_07) |
        ({16{~|(read_addr ^ 4'h8)}} & out_08) |
        ({16{~|(read_addr ^ 4'h9)}} & out_09) |
        ({16{~|(read_addr ^ 4'hA)}} & out_0A) |
        ({16{~|(read_addr ^ 4'hB)}} & out_0B) |
        ({16{~|(read_addr ^ 4'hC)}} & out_0C) |
        ({16{~|(read_addr ^ 4'hD)}} & out_0D) |
        ({16{~|(read_addr ^ 4'hE)}} & out_0E) |
        ({16{~|(read_addr ^ 4'hF)}} & out_0F);

endmodule