// ==========================
// 8-Bit CPU Definitions)
// ==========================

`ifndef DEFINES_VH
`define DEFINES_VH

`define STATE_FETCH 2'b00
`define STATE_DECODE 2'b01
`define STATE_EXECUTE 2'b10
`define STATE_HALT 2'b11

// --- 4-bit Opcodes ---
`define OPCODE_NOP 4'b0000 // No Operation
`define OPCODE_HLT 4'b0001 // Halt
`define OPCODE_ADD 4'b0010 // Addition
`define OPCODE_SUB 4'b0011 // Subtraction
`define OPCODE_NOR 4'b0100 // Bitwise NOR
`define OPCODE_AND 4'b0101 // Bitwise AND
`define OPCODE_XOR 4'b0110 // Bitwise XOR
`define OPCODE_RSH 4'b0111 // Right Shift
`define OPCODE_LDI 4'b1000 // Load Immediate
`define OPCODE_ADI 4'b1001 // Add Immediate

// For later uses
`define OPCODE_JMP 4'b1010 // Jump
`define OPCODE_BRH 4'b1011 // Branch
`define OPCODE_CAL 4'b1100 // Call
`define OPCODE_RET 4'b1101 // Return
`define OPCODE_LOD 4'b1110 // Memory Load
`define OPCODE_STR 4'b1111 // Memory Store

// --- Instruction Types ---
`define TYPE_N 3'b000
`define TYPE_R 3'b001
`define TYPE_I 3'b010
`define TYPE_D 3'b011
`define TYPE_A 3'b100

// --- Register addresses (4 bit) ---
`define REG_R0 4'b0000
`define REG_R1 4'b0001
`define REG_R2 4'b0010
`define REG_R3 4'b0011
`define REG_R4 4'b0100
`define REG_R5 4'b0101
`define REG_R6 4'b0110
`define REG_R7 4'b0111
`define REG_R8 4'b1000
`define REG_R9 4'b1001
`define REG_R10 4'b1010
`define REG_R11 4'b1011
`define REG_R12 4'b1100
`define REG_R13 4'b1101
`define REG_R14 4'b1110
`define REG_R15 4'b1111

// --- ALU Flags (Flag Indexes) ---
`define FLAG_Z 0 // Zero Flag Index
`define FLAG_C 1 // Carry Flag Index
`define FLAG_N 2 // Negative Flag Index
`define FLAG_V 3 // Overflow Flag Index

`endif