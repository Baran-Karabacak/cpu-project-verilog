`timescale 1ns / 1ps
`include "defines.vh"

module register_file (
    input wire clk, // System Clock
    input wire rst, // Synchronous Reset
    input wire we, // Global Write Enable from Dispatcher
    input wire [3:0] write_addr, // 4-bit destination register address
    input wire [7:0] write_data, // 8-bit data to be written
    input wire [3:0] read_addr_a, // 4-bit source register address (Port A)
    input wire [3:0] read_addr_b, // 4-bit source register address (Port B)
    output wire [7:0] read_data_a,  // 8-bit output data (Port A)
    output wire [7:0] read_data_b   // 8-bit output data (Port B)
);

    // --- Output Wire Array (Internal Data Bus) ---
    // Note: This is not a memory. It is purely 2D bundle of physical wires connecting
    // the outputs of the 16 registers to the inputs of the read multiplexers
    wire [7:0] reg_out [0:15];

    // --- Wire Address Decoder (4-to-16 DEMUX) ---
    // Generates 15 individual Write Enable signals using AND gates (R0 is zero register so I don't include it)
    // A register only gets written if the Global WE is high AND its address matches
    wire [15:1] reg_we;

    assign reg_we[1]  = we & ~|(write_addr ^ `REG_R1);
    assign reg_we[2]  = we & ~|(write_addr ^ `REG_R2);
    assign reg_we[3]  = we & ~|(write_addr ^ `REG_R3);
    assign reg_we[4]  = we & ~|(write_addr ^ `REG_R4);
    assign reg_we[5]  = we & ~|(write_addr ^ `REG_R5);
    assign reg_we[6]  = we & ~|(write_addr ^ `REG_R6);
    assign reg_we[7]  = we & ~|(write_addr ^ `REG_R7);
    assign reg_we[8]  = we & ~|(write_addr ^ `REG_R8);
    assign reg_we[9]  = we & ~|(write_addr ^ `REG_R9);
    assign reg_we[10] = we & ~|(write_addr ^ `REG_R10);
    assign reg_we[11] = we & ~|(write_addr ^ `REG_R11);
    assign reg_we[12] = we & ~|(write_addr ^ `REG_R12);
    assign reg_we[13] = we & ~|(write_addr ^ `REG_R13);
    assign reg_we[14] = we & ~|(write_addr ^ `REG_R14);
    assign reg_we[15] = we & ~|(write_addr ^ `REG_R15);

    // --- Hardware Instantiation ---
    // R0 is a Hardwired Zero Register. No flip-flops are synthesized.
    // Any read from R0 directly reads Ground (0 Volts)
    assign reg_out[0] = 8'b00000000;
    
    cpu_register #(.WIDTH(8)) r1 (.clk(clk), .rst(rst), .we(reg_we[1]), .data_in(write_data), .data_out(reg_out[1]));
    cpu_register #(.WIDTH(8)) r2 (.clk(clk), .rst(rst), .we(reg_we[2]), .data_in(write_data), .data_out(reg_out[2]));
    cpu_register #(.WIDTH(8)) r3 (.clk(clk), .rst(rst), .we(reg_we[3]), .data_in(write_data), .data_out(reg_out[3]));
    cpu_register #(.WIDTH(8)) r4 (.clk(clk), .rst(rst), .we(reg_we[4]), .data_in(write_data), .data_out(reg_out[4]));
    cpu_register #(.WIDTH(8)) r5 (.clk(clk), .rst(rst), .we(reg_we[5]), .data_in(write_data), .data_out(reg_out[5]));
    cpu_register #(.WIDTH(8)) r6 (.clk(clk), .rst(rst), .we(reg_we[6]), .data_in(write_data), .data_out(reg_out[6]));
    cpu_register #(.WIDTH(8)) r7 (.clk(clk), .rst(rst), .we(reg_we[7]), .data_in(write_data), .data_out(reg_out[7]));
    cpu_register #(.WIDTH(8)) r8 (.clk(clk), .rst(rst), .we(reg_we[8]), .data_in(write_data), .data_out(reg_out[8]));
    cpu_register #(.WIDTH(8)) r9 (.clk(clk), .rst(rst), .we(reg_we[9]), .data_in(write_data), .data_out(reg_out[9]));
    cpu_register #(.WIDTH(8)) r10 (.clk(clk), .rst(rst), .we(reg_we[10]), .data_in(write_data), .data_out(reg_out[10]));
    cpu_register #(.WIDTH(8)) r11 (.clk(clk), .rst(rst), .we(reg_we[11]), .data_in(write_data), .data_out(reg_out[11]));
    cpu_register #(.WIDTH(8)) r12 (.clk(clk), .rst(rst), .we(reg_we[12]), .data_in(write_data), .data_out(reg_out[12]));
    cpu_register #(.WIDTH(8)) r13 (.clk(clk), .rst(rst), .we(reg_we[13]), .data_in(write_data), .data_out(reg_out[13]));
    cpu_register #(.WIDTH(8)) r14 (.clk(clk), .rst(rst), .we(reg_we[14]), .data_in(write_data), .data_out(reg_out[14]));
    cpu_register #(.WIDTH(8)) r15 (.clk(clk), .rst(rst), .we(reg_we[15]), .data_in(write_data), .data_out(reg_out[15]));

    // --- Read Multiplexers (16-to-1 MUX)
    // The Verilog array indexing operator [] is synthesized directly into a
    // massive hardware Multiplexer tree. It physically routes the selected
    // register's output wires to the read_data ports based on the read address.
    // The code is already far from clean anyway, so I might as well do it manually.
    // ~| operator is same as ==. 
    assign read_data_a = 
        ({8{~|(read_addr_a ^ 4'b0000)}} & reg_out[0]) |
        ({8{~|(read_addr_a ^ 4'b0001)}} & reg_out[1]) |
        ({8{~|(read_addr_a ^ 4'b0010)}} & reg_out[2]) |
        ({8{~|(read_addr_a ^ 4'b0011)}} & reg_out[3]) |
        ({8{~|(read_addr_a ^ 4'b0100)}} & reg_out[4]) |
        ({8{~|(read_addr_a ^ 4'b0101)}} & reg_out[5]) |
        ({8{~|(read_addr_a ^ 4'b0110)}} & reg_out[6]) |
        ({8{~|(read_addr_a ^ 4'b0111)}} & reg_out[7]) |
        ({8{~|(read_addr_a ^ 4'b1000)}} & reg_out[8]) |
        ({8{~|(read_addr_a ^ 4'b1001)}} & reg_out[9]) |
        ({8{~|(read_addr_a ^ 4'b1010)}} & reg_out[10]) |
        ({8{~|(read_addr_a ^ 4'b1011)}} & reg_out[11]) |
        ({8{~|(read_addr_a ^ 4'b1100)}} & reg_out[12]) |
        ({8{~|(read_addr_a ^ 4'b1101)}} & reg_out[13]) |
        ({8{~|(read_addr_a ^ 4'b1110)}} & reg_out[14]) |
        ({8{~|(read_addr_a ^ 4'b1111)}} & reg_out[15]);

    assign read_data_a =
        ({8{~|(read_addr_b ^ 4'b0000)}} & reg_out[0]) |
        ({8{~|(read_addr_b ^ 4'b0001)}} & reg_out[1]) |
        ({8{~|(read_addr_b ^ 4'b0010)}} & reg_out[2]) |
        ({8{~|(read_addr_b ^ 4'b0011)}} & reg_out[3]) |
        ({8{~|(read_addr_b ^ 4'b0100)}} & reg_out[4]) |
        ({8{~|(read_addr_b ^ 4'b0101)}} & reg_out[5]) |
        ({8{~|(read_addr_b ^ 4'b0110)}} & reg_out[6]) |
        ({8{~|(read_addr_b ^ 4'b0111)}} & reg_out[7]) |
        ({8{~|(read_addr_b ^ 4'b1000)}} & reg_out[8]) |
        ({8{~|(read_addr_b ^ 4'b1001)}} & reg_out[9]) |
        ({8{~|(read_addr_b ^ 4'b1010)}} & reg_out[10]) |
        ({8{~|(read_addr_b ^ 4'b1011)}} & reg_out[11]) |
        ({8{~|(read_addr_b ^ 4'b1100)}} & reg_out[12]) |
        ({8{~|(read_addr_b ^ 4'b1101)}} & reg_out[13]) |
        ({8{~|(read_addr_b ^ 4'b1110)}} & reg_out[14]) |
        ({8{~|(read_addr_b ^ 4'b1111)}} & reg_out[15]);

endmodule