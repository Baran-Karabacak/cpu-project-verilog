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

    // --- Hardware Control Signals ---
    wire is_type_r;
    wire is_type_i;
    wire is_type_d;
    wire is_opcode_lod;
    wire is_opcode_str;

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

    wire [3:0] raw_opcode = instruction[15:12];

    // --- Decoding Specific Opcodes (Reduction NOR for Gate-Level Safety) ---
    assign is_opcode_lod = ~|(raw_opcode ^ `OPCODE_LOD);
    assign is_opcode_str = ~|(raw_opcode ^ `OPCODE_STR);
    assign is_type_d     = is_opcode_lod | is_opcode_str;

    // --- Data Routing & Address Extraction (Pure MUX Gates) ---
    // Dest Register MUX (LOD ise field2, değilse field1)
    assign reg_addr_dest = field1;
        
    // Port A MUX (D-Type ise field1, değilse field2)
    assign reg_addr_a = field2;
        
    // Port B MUX (D-Type ise field2, değilse field3)
    assign reg_addr_b = ({4{is_opcode_str}} & field1) | 
                        ({4{~is_opcode_str}} & field3);

    // Immediate Value MUX (D-Type ise 4 bit Offset, değilse field2+field3)
    assign imm_val = ({8{is_type_d}} & {4'b0000, field3}) | 
                     ({8{~is_type_d}} & {field2, field3});


    // --- Hardware Control ---
    
    assign is_type_r = ~|(inst_type ^ `TYPE_R);
    assign is_type_i = ~|(inst_type ^ `TYPE_I);

    // BUG FIX 1: ALU Enable -> D-Type komutlarda adres hesaplamak için uyanmak zorundadır!
    assign alu_enable = is_type_r | is_type_i | is_type_d;

    // BUG FIX 2: ALU OP -> D-Type komutlarında (LOD/STR) adresi bulmak için ALU'ya zorla ADD (010) yaptırılır.
    assign alu_op = ({3{is_type_d}} & 3'b010) | 
                    ({3{~is_type_d}} & decoded_opcode);

    // ALU Source B: Type I (Immediate) ve Type D (Offset) için 1 olur.
    assign alu_src_b = is_type_i | is_type_d;

    // Register Write: Type R, Type I ve bellekten yükleme (LOD) anında aktif.
    assign reg_we = is_type_r | is_type_i | is_opcode_lod;

    // Memory Write: Sadece Store (STR) komutunda aktif.
    assign mem_we = is_opcode_str;

    // Memory to Reg: 1 ise RAM'den gelen veri, 0 ise ALU sonucu.
    assign mem_to_reg = is_opcode_lod;

    // --- Control Flow ---
    wire is_jmp = ~|(raw_opcode ^ `OPCODE_JMP);
    wire is_brh = ~|(raw_opcode ^ `OPCODE_BRH);
    
    wire [3:0] cond_field = instruction[11:8];

    wire is_condition_met = 
            ({1{~|(cond_field ^ 4'h0)}} & alu_flags[`FLAG_Z]) |
            ({1{~|(cond_field ^ 4'h1)}} & alu_flags[`FLAG_C]) |
            ({1{~|(cond_field ^ 4'h2)}} & alu_flags[`FLAG_N]) |
            ({1{~|(cond_field ^ 4'h3)}} & alu_flags[`FLAG_V]);

    // 1 forces Program Counter to intercept and jump
    assign pc_src = is_jmp | (is_brh & is_condition_met);

    // Halt
    assign is_hlt = ~|(raw_opcode ^ `OPCODE_HLT);

    // Load Immediate: Reduction NOR ile güvenli kontrol
    assign load_imm = ~|(raw_opcode ^ `OPCODE_LDI);

endmodule