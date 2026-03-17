`timescale 1ns / 1ps
`include "defines.vh"

module cpu_core (
    input wire clk, // System Clock
    input wire rst // System Reset
);

    // --- Internal Busses ---
    
    // Instruction & Program Counter Busses
    wire [15:0] pc_current;
    wire [15:0] pc_next;
    wire [15:0] instruction;

    // Control Signals From Dispatcher
    wire reg_we;
    wire mem_we;
    wire alu_enable;
    wire [2:0] alu_op;
    wire alu_src_b;
    wire mem_to_reg;
    wire pc_src;
    wire is_hlt;
    wire load_imm;

    // Data & Address Routing Busses
    wire [3:0] reg_addr_a;
    wire [3:0] reg_addr_b;
    wire [3:0] reg_addr_dest;
    wire [7:0] imm_val;

    // Datapath Busses
    wire [7:0] reg_data_a;
    wire [7:0] reg_data_b;
    wire [7:0] reg_write_data;

    // ALU Specific Wires
    wire [7:0] alu_operand_b; // The wire going to ALU's second leg
    wire [7:0] alu_result;
    wire alu_raw_carry;
    wire flag_z, flag_c, flag_n, flag_v;
    wire [3:0] alu_flags_bus;

    // Data Memory Placeholder (For future versions)
    wire [7:0] data_memory_read = 8'b00000000;

    // --- Hardware Routing Multiplexers ---

    // ALU Source B Mux: Decides between Register B data and Immediate Value
    assign alu_operand_b = 
                    ({8{alu_src_b}} & imm_val) |
                    ({8{~alu_src_b}} & reg_data_b);
    
    // Writeback MUX: Decides between ALU result and Data Memory
    assign reg_write_data = 
                    ({8{mem_to_reg}}  & data_memory_read) | 
                    ({8{load_imm}}    & imm_val) |
                    ({8{~mem_to_reg & ~load_imm}} & alu_result);

    // Program Counter Logic: Adder for PC+1 and MUX for Branching
    wire [15:0] pc_plus_one;
    inc_16bit pc_incrementer (
        .in_val(pc_current),
        .out_val(pc_plus_one)
    );
    wire [15:0] jump_target = {8'b00000000, imm_val};

    // PC Source MUX: 1 for Branch/Jump, 0 for Normal Execution
    assign pc_next = ({16{pc_src}}  & jump_target) | 
                     ({16{~pc_src}} & pc_plus_one);

    // Bundling individual flags into the 4-bit status bus for the Dispatcher
    // Order strictly follows defines.vh: {V, N, C, Z}
    assign alu_flags_bus = {flag_v, flag_n, flag_c, flag_z};


    // --- Hardware Instantiations ---

    // Program Counter
    program_counter pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_we(~is_hlt), // Stops if Halt signal comes from Dispatcher
        .next_pc(pc_next),
        .current_pc(pc_current)
    );

    // Instruction Memory (ROM)
    instruction_memory rom_inst(
        .read_addr(pc_current),
        .instruction_out(instruction)
    );

    // Dispatcher
    dispatcher ctrl_inst (
        .instruction(instruction),
        .alu_flags(alu_flags_bus),
        .reg_we(reg_we),
        .mem_we(mem_we),
        .alu_enable(alu_enable),
        .alu_op(alu_op),
        .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg),
        .pc_src(pc_src),
        .reg_addr_a(reg_addr_a),
        .reg_addr_b(reg_addr_b),
        .reg_addr_dest(reg_addr_dest),
        .imm_val(imm_val),
        .is_hlt(is_hlt),
        .load_imm(load_imm)
    );

    // Register File
    register_file reg_inst (
        .clk(clk),
        .rst(rst),
        .we(reg_we),
        .read_addr_a(reg_addr_a),
        .read_addr_b(reg_addr_b),
        .write_addr(reg_addr_dest),
        .write_data(reg_write_data),
        .read_data_a(reg_data_a),
        .read_data_b(reg_data_b)    
    );



    // ALU
    alu alu_inst (
        .parsed_opcode(alu_op),
        .in_B(reg_data_a),
        .in_C(alu_operand_b),
        .out_A(alu_result),
        .carry_out(alu_raw_carry)
    );

    wire is_sub_signal = ~alu_op[2] & alu_op[1] & alu_op[0];

    flag_generator flag_unit (
        .alu_result(alu_result),
        .alu_carry_out(alu_raw_carry),
        .a7(reg_data_a[7]),
        .b7(alu_operand_b[7]),
        .is_sub(is_sub_signal),
        .is_arithmetic(alu_enable),
        .flag_zero(flag_z),
        .flag_carry(flag_c),
        .flag_negative(flag_n),
        .flag_overflow(flag_v)
    );

endmodule