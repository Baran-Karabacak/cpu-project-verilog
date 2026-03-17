`timescale 1ns / 1ps
`include "defines.vh"

// The central brain of the CPU. Instantiates the instruction decoder 
// and drives the entire datapath.
module dispatcher (
    input wire [15:0] instruction, // 16-bit raw machine code from Instruction Memory(ROM)
    input wire [3:0] alu_flags, // Status flags {V, N, Z, C} from the ALU
    output wire reg_we, // Register File Write Enable
    output wire mem_we, // Data Memory Write Enable
    output wire alu_enable, // Wakes up the ALU
    output wire [2:0] alu_op, // 3-bit ALU operation selector
    output wire alu_src_b, // 0: Register B, 1: Immediate Value
    output wire mem_to_reg, // 0: ALU Result to Reg, 1: Memory to Reg
    output wire pc_src, // 0: PC+1 (Normal Flow), 1: Branch/Jump
    output wire [3:0] reg_addr_a, // Source Register 1
    output wire [3:0] reg_addr_b, // Source Register 2
    output wire [3:0] reg_addr_dest, // Destination Register
    output wire [7:0] imm_val, // 8-bit Immediate Data payload
    output wire is_hlt, // 1 if Opcode is Halt
    output wire load_imm // 1: Bypass ALU and load immediate directly
);

    // --- Instruction Decoding ---
    wire [2:0] decoded_opcode;
    wire [3:0] field1, field2, field3;
    wire [2:0] inst_type;

    instruction_decoder decoder_inst (
        .instruction(instruction),
        .opcode_output(decoded_opcode),
        .field1(field1),
        .field2(field2),
        .field3(field3),
        .instruction_type(inst_type)
    );

    // Extracting the raw top 4 bits to make specific instruction routing easier
    wire [3:0] raw_opcode = instruction[15:12];

    // --- Data Routing & Address Extraction
    // Pure wire assignments. The datapath multiplexers will filter out the noise.
    assign reg_addr_dest = field1; 
    assign reg_addr_a = field2;
    assign reg_addr_b = field3;

    // Combining the lower 8 bits directly from the fields for immediate values
    assign imm_val = {field2, field3};

    // --- Hardware Control ---
    wire is_type_r;
    wire is_type_i;

    wire is_opcode_lod; // Load
    wire is_opcode_str; // Store

    // ALU Control : Awake only for Type I and Type R instructions
    assign is_type_r = ~|(inst_type ^ `TYPE_R);
    assign is_type_i = ~|(inst_type ^ `TYPE_I);

    assign alu_enable = is_type_r | is_type_i;

    // ALU OP: Direct passthrough from the decoder
    assign alu_op = decoded_opcode;

    // ALU Source B: If Type I (Immediate Math) or Memory Ops, route the Immediate Wire
    assign is_opcode_lod = ~|(raw_opcode ^ `OPCODE_LOD);
    
    assign is_opcode_str = ~|(raw_opcode ^ `OPCODE_STR);
        
    assign alu_src_b = is_type_i | is_opcode_lod | is_opcode_str;

    // Register Write: Unlock the register file for Type R, Type I, and Load from Memory
    assign reg_we = is_type_r | is_type_i | is_opcode_lod;

    // Memory Write: Only unlock Data Memory when a Store instruction is active
    assign mem_we = is_opcode_str;

    // Memory to Reg: 1 if loading from Data Memory, 0 if taking the ALU's calculated result
    assign mem_to_reg = is_opcode_lod;

    // --- Control Flow ---
    wire is_jmp = ~|(raw_opcode ^ `OPCODE_JMP);
    wire is_brh = ~|(raw_opcode ^ `OPCODE_BRH);

    wire is_condition_met = alu_flags[`FLAG_Z];

    // 1 forces Program Counter to intercept and jump
    assign pc_src = is_jmp | (is_brh & is_condition_met);

    // Halt
    assign is_hlt = ~|(raw_opcode ^ `OPCODE_HLT);

    assign load_imm = raw_opcode[3] & ~raw_opcode[2] & ~raw_opcode[1] & ~raw_opcode[0];



endmodule