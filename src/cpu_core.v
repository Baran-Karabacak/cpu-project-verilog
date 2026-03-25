`timescale 1ns / 1ps
`include "defines.vh"

module cpu_core (
    input wire clk, // System Clock
    input wire rst // System Reset
);

    // --- Internal Busses ---
    
    wire [15:0] pc_plus_one;
    
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
    wire stack_push;
    wire stack_pop;
    wire [1:0] pc_src_mux;
    wire [15:0] stack_data_out;
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

    // Data Memory
    wire [7:0] data_memory_read;
    
    data_memory ram_inst (
        .clk(clk),
        .rst(rst),
        .we(mem_we),
        .addr(alu_result),
        .data_in(reg_data_b),
        .data_out(data_memory_read)
    );
    
    hardware_stack call_stack (
        .clk(clk),
        .rst(rst),
        .push(stack_push),
        .pop(stack_pop),
        .data_in(pc_plus_one),
        .data_out(stack_data_out)
    );

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
    inc_16bit pc_incrementer (
        .in_val(pc_current),
        .out_val(pc_plus_one)
    );
    wire [15:0] jump_target = {8'b00000000, imm_val};

    // PC Source MUX: 1 for Branch/Jump, 0 for Normal Execution
    assign pc_next =
            ({16{~pc_src_mux[1] & ~pc_src_mux[0]}} & pc_plus_one) | 
            ({16{~pc_src_mux[1] &  pc_src_mux[0]}} & jump_target) | 
            ({16{ pc_src_mux[1] & ~pc_src_mux[0]}} & stack_data_out);

    // Bundling individual flags into the 4-bit status bus for the Dispatcher
    // Order strictly follows defines.vh: {V, N, C, Z}
    wire [3:0] raw_flags = {flag_v, flag_n, flag_c, flag_z};
    wire [3:0] saved_flags;

    // README'ye göre Bayrakları değiştiren komutlar: ADD, SUB, NOR, AND, XOR, ADI
    wire op_is_add = ~|(instruction[15:12] ^ `OPCODE_ADD);
    wire op_is_sub = ~|(instruction[15:12] ^ `OPCODE_SUB);
    wire op_is_nor = ~|(instruction[15:12] ^ `OPCODE_NOR);
    wire op_is_and = ~|(instruction[15:12] ^ `OPCODE_AND);
    wire op_is_xor = ~|(instruction[15:12] ^ `OPCODE_XOR);
    wire op_is_adi = ~|(instruction[15:12] ^ `OPCODE_ADI);

    // Write Enable: Sadece bu komutlar çalışırken bayrak kasasının kapağını aç!
    wire flags_we = op_is_add | op_is_sub | op_is_nor | op_is_and | op_is_xor | op_is_adi;

    // 4-Bit Bayrak Kayıtçısı
    cpu_register #(.WIDTH(4)) status_register (
        .clk(clk),
        .rst(rst),
        .we(flags_we),
        .data_in(raw_flags),
        .data_out(saved_flags)
    );

    // Dispatcher artık rüzgarda savrulan kabloları değil, kilitli kasayı okuyacak:
    assign alu_flags_bus = saved_flags;


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
        .stack_push(stack_push),
        .stack_pop(stack_pop),
        .pc_src_mux(pc_src_mux),
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