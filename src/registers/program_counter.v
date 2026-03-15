`timescale 1ns/1ps

// The 16-bit Program Counter (PC) register
// Acts as the primary address pointer for the Instruction Memory
// Uses the parameterized cpu_register module
module program_counter (
    input wire clk, // System Clock
    input wire rst, // Synchronous Reset (Pulls PC strictly to 0x0000)
    input wire pc_we, // Write Enable (0 stalls the CPU, 1 advances it)
    input wire [15:0] next_pc, // Next address from the routing multiplexer (PC+1 or Branch Target)
    output wire [15:0] current_pc // Current execution address sent to ROM
);

    // --- Hardware Instantiation ---
    // By overriding the WIDTH parameter to 16, we instantly deploy our
    // register architecture without writing a single line of behavioral logic.
    cpu_register #(
        .WIDTH(16)
    ) pc_reg (
        .clk(clk),
        .rst(rst),
        .we(pc_we),
        .data_in(next_pc),
        .data_out(current_pc)
    );

endmodule