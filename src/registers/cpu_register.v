`timescale 1ns / 1ps

// 3 gate and
module cpu_register #(
    parameter WIDTH = 8
)(
    input wire clk, // System Clock
    input wire rst, // Synchronous Reset
    input wire we, // Write Enable
    input wire [WIDTH-1:0] data_in, // Input data
    output reg [WIDTH-1:0] data_out // Output data
);

    // Write Enable Logic
    // we == 1 -> loads data_in
    // we == 0 -> holds its own data_out
    // Basically it is a MUX
    wire [WIDTH-1:0] hold_or_load;
    assign hold_or_load = (data_in & {WIDTH{we}}) | (data_out & {WIDTH{~we}});

    // Reset Logic
    // rst == 1 -> resets all bits with AND
    wire [WIDTH-1:0] next_state;
    assign next_state = hold_or_load & {WIDTH{~rst}};

    // D Flip-Flop
    // I'm not a fan of using always blocks, but they are necessary to avoid issues with the CPU clock.
    always @(posedge clk) begin
        data_out <= next_state;
    end
