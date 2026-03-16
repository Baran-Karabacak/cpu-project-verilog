`timescale 1ns / 1ps

module cpu_core_tb();

    reg clk;
    reg rst;

    cpu_core uut(
        .clk(clk),
        .rst(rst)
    );

    // Clock Generator
    // Flips the clock every 5 nanoseconds
    always begin
        #5 clk = ~clk;
    end

    initial begin
        $dumpfile("build/cpu_core_tb.vcd");
        $dumpvars(0, cpu_core_tb);

        // Power On and assert System Reset
        clk = 0;
        rst = 1;
        $display("INFO: System Reset Asserted.");

        // Hold reset for 20 nanoseconds (2 clock cycles) to ensure stability
        #20;

        // Release Reset and let the CPU run the machine code from ROM
        rst = 0;
        $display("INFO: System Reset Released.");

        // Let the CPU run for a sufficient amount of time (e.g., 1000 ns)
        // Adjust this time based on how long your hex program is.
        #1000;

        // Stop the simulation
        $display("INFO: Simulation Time Limit Reached. Shutting down.");
        $finish;
    end

endmodule