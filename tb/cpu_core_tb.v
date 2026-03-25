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
        #100000;

        // Stop the simulation
        $display("INFO: Simulation Time Limit Reached. Shutting down.");
        $finish;
    end
    
    // 6. Memory-Mapped I/O Exfiltration
    integer io_log;

    initial begin
        #21;
        io_log = $fopen("build/io_trace.csv", "w");
    end

    // Sadece Saatin Yükselen Kenarında (RAM'e yazma anı) ve Adres >= 240 ise
    always @(posedge clk) begin
        if (!rst && uut.mem_we && uut.alu_result >= 8'hF0) begin
            // Format: Adres, Veri (Örnek: 240, 15 -> Pixel X = 15)
            $fdisplay(io_log, "%d,%d", uut.alu_result, uut.reg_data_b);
        end
    end

endmodule