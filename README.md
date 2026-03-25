# 8-Bit CPU — Verilog Implementation

A custom 8-bit CPU designed in Verilog, featuring a 16-bit instruction ISA, a carry lookahead ALU, a 16-register file, memory-mapped I/O, and a Rust-based ROM builder toolchain.

---

## Architecture Overview

- **Data width**: 8-bit
- **Instruction width**: 16-bit
- **Registers**: 16 × 8-bit general-purpose registers (`r0`–`r15`); `r0` is a hardwired zero register
- **Instruction memory**: Up to 2048 instructions (10-bit address, 2 bytes each)
- **Data memory**: 256 bytes (8-bit address); addresses 240–255 are memory-mapped I/O
- **Stack**: Hardware stack for `CAL`/`RET`, maximum depth 16
- **ALU flags**: Zero (Z), Carry (C), Overflow (O), Negative (N)
- **Execution model**: Single-cycle (combinational datapath, synchronous writeback)

---

## Instruction Format

All instructions are 16 bits wide:

```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opcode (4)  |   Field A (4)  |   Field B (4)  |   Field C (4)
```


Field usage depends on the instruction type:

**N-type** (`000`) — No operands
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opcode (4)  |         (unused — must be zero)
```
Instructions: `NOP`, `HLT`, `RET`

**R-type** (`001`) — Register-register operation
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opcode (4)  |  Dest reg (4)  |  Src reg A (4) |  Src reg B (4)
```
Instructions: `ADD`, `SUB`, `NOR`, `AND`, `XOR`, `RSH`

**I-type** (`010`) — Immediate operand
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opcode (4)  |  Dest reg (4)  |        Immediate (8)
```
Instructions: `LDI`, `ADI`

**D-type** (`011`) — Memory access with offset
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opcode (4)  |  Base reg (4)  |  Data reg (4)  |  Offset (4)
```
Instructions: `LOD`, `STR`
- **LOD**: `Data ← Mem[Base + offset]`
- **STR**: `Mem[Base + offset] ← Data`

**A-type** (`100`) — Control flow / address
```
 15  14  13  12 | 11  10   9   8 |  7   6   5   4 |  3   2   1   0
 ───────────────┼────────────────┼────────────────┼───────────────
    Opcode (4)  |  Condition (4) |            Address (8)
```
Instructions: `JMP`, `BRH`, `CAL`
- For `JMP` and `CAL` the condition field is unused
- For `BRH` the condition field selects the flag to test (e.g. Z flag)


---

## Instruction Set

### Core Instructions

| Opcode | Mnemonic | Description | Operands | Sets Flags | Pseudocode |
|--------|----------|-------------|----------|------------|------------|
| `0000` | `NOP` | No operation | — | No | — |
| `0001` | `HLT` | Halt execution | — | No | — |
| `0010` | `ADD` | Addition | rA, rB → rC | Yes | `A ← B + C` |
| `0011` | `SUB` | Subtraction | rA, rB → rC | Yes | `A ← B - C` |
| `0100` | `NOR` | Bitwise NOR | rA, rB → rC | Yes | `A ← !(B \| C)` |
| `0101` | `AND` | Bitwise AND | rA, rB → rC | Yes | `A ← B & C` |
| `0110` | `XOR` | Bitwise XOR | rA, rB → rC | Yes | `A ← B ^ C` |
| `0111` | `RSH` | Right shift (logical) | rA → rC | No | `A ← C >> 1` |
| `1000` | `LDI` | Load immediate | rA, imm8 | No | `A ← imm` |
| `1001` | `ADI` | Add immediate | rA, imm8 | Yes | `A ← A + imm` |
| `1010` | `JMP` | Unconditional jump | addr | No | `PC ← addr` |
| `1011` | `BRH` | Conditional branch | cond, addr | No | `PC ← cond ? addr : PC+1` |
| `1100` | `CAL` | Call subroutine | addr | No | `push PC+1; PC ← addr` |
| `1101` | `RET` | Return from subroutine | — | No | `PC ← pop` |
| `1110` | `LOD` | Load from memory | rA, rB, offset | No | `B ← Mem[A + offset]` |
| `1111` | `STR` | Store to memory | rA, rB, offset | No | `Mem[A + offset] ← B` |

<!-- ### Pseudo-Instructions

These are assembler conveniences that expand to core instructions:

| Mnemonic | Notation | Expands to | Pseudocode |
|----------|----------|------------|------------|
| `CMP` | `CMP A B` | `SUB r0 A B` | `A - B` (sets flags) |
| `MOV` | `MOV A C` | `ADD A r0 C` | `A ← C` |
| `LSH` | `LSH A C` | `ADD A C C` | `A ← C << 1` |
| `INC` | `INC A` | `ADI A 1` | `A ← A + 1` |
| `DEC` | `DEC A` | `ADI A -1` | `A ← A - 1` |
| `NOT` | `NOT A C` | `NOR A r0 C` | `A ← !C` |
| `NEG` | `NEG A C` | `SUB r0 A C` | `C ← 0 - A` |

--- -->

<!-- ## Memory-Mapped I/O

Addresses 240–255 in data memory are reserved for hardware I/O:

| Address | R/W | Name | Description |
|---------|-----|------|-------------|
| 240 | Write | Pixel X | Bottom 5 bits = X coordinate |
| 241 | Write | Pixel Y | Bottom 5 bits = Y coordinate |
| 242 | Write | Draw Pixel | Draw pixel at (X, Y) to buffer |
| 243 | Write | Clear Pixel | Clear pixel at (X, Y) from buffer |
| 244 | Read  | Load Pixel | Read pixel value at (X, Y) |
| 245 | Write | Buffer Screen | Push screen buffer to display |
| 246 | Write | Clear Screen Buffer | Clear screen buffer |
| 247 | Write | Write Char | Write character to display buffer |
| 248 | Write | Buffer Chars | Push character buffer to display |
| 249 | Write | Clear Chars Buffer | Clear character buffer |
| 250 | Write | Show Number | Show number on number display |
| 251 | Write | Clear Number | Clear number display |
| 252 | Write | Signed Mode | Interpret number as 2's complement `[-128, 127]` |
| 253 | Write | Unsigned Mode | Interpret number as unsigned `[0, 255]` |
| 254 | Read  | RNG | Load a random 8-bit number |
| 255 | Read  | Controller Input | Read controller state (Start, Select, A, B, ↑↓←→) |

--- -->

## Project Structure

```
.
├── src/
│   ├── cpu_core.v               # Top-level CPU module
│   ├── defines.vh               # Global constants and ISA definitions
│   ├── instruction_memory.v     # Auto-generated ROM (do not edit manually)
│   ├── alu/
│   │   ├── alu.v                # 8-bit ALU (MUX over 8 operations)
│   │   └── flag_generator.v     # Z, C, N, V flag logic
│   ├── control/
│   │   ├── dispatcher.v         # Control unit — generates all datapath signals
│   │   ├── instruction_decoder.v
│   │   ├── opcode_decoder.v
│   │   └── type_decoder.v
│   ├── registers/
│   │   ├── cpu_register.v       # Parameterized D flip-flop
│   │   ├── register_file.v      # 16 × 8-bit register file
│   │   └── program_counter.v    # 16-bit PC
│   ├── math_core/
│   │   ├── cla_4bit.v           # 4-bit carry lookahead adder
│   │   ├── cla_8bit.v           # 8-bit CLA (two 4-bit blocks)
│   │   ├── add_sub_8bit.v       # Unified add/subtract unit
│   │   └── inc_16bit.v          # PC+1 incrementer
│   ├── logic_core/
│   │   └── bitwise_ops.v        # AND, OR, NOR, XOR, RSH
│   └── routing/
│       └── mux_8to1_8bit.v      # 8-input 8-bit multiplexer
├── tb/
│   └── cpu_core_tb.v            # Simulation testbench
├── tools/
│   └── rom_builder/             # Rust tool: hex → instruction_memory.v
│       └── src/
│           ├── main.rs
│           ├── lib.rs
│           ├── parser.rs        # Hex file parser with comment support
│           └── generator.rs     # Verilog case-statement ROM generator
├── programs/
│   └── input.hex                # Machine code input for the ROM builder
└── Makefile
```

---

## Building & Running

### Prerequisites

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`)
- [GTKWave](http://gtkwave.sourceforge.net/) (optional, for waveforms)
- [Rust](https://rustup.rs/) (for the ROM builder)

### Commands

```bash
make all          # Full flow: generate ROM → compile → simulate
make generate_rom # Build instruction_memory.v from programs/input.hex
make compile      # Compile Verilog with iverilog
make run          # Run simulation with vvp
make wave         # Open waveform in GTKWave
```

### Writing Programs

Programs are written as hex files. Each line is one 16-bit instruction (up to 4 hex digits). Comments (`//`) and blank lines are supported.

```
// Load the value 5 into r1
8105    // LDI r1, 5

// Load the value 3 into r2
8203    // LDI r2, 3

// Add r2 + r3 → r1
2123    // ADD r1 r2 r3

// Halt
1000    // HLT
```

Run `make generate_rom` to compile `programs/input.hex` into `src/instruction_memory.v`, then `make run` to simulate.

---

## Datapath

```
         ┌─────────────┐
PC ──────►│ Instr. Mem  │──► instruction[15:0]
         └─────────────┘
                │
         ┌─────────────┐
         │  Dispatcher │──► reg_we, alu_enable, alu_op,
         │ (Control)   │    alu_src_b, mem_to_reg,
         └─────────────┘    pc_src, is_hlt
                │
    ┌───────────┼───────────┐
    ▼           ▼           ▼
 Reg File     ALU        Data Mem
(16×8-bit)  (8-bit)    (256 bytes)
    │           │           │
    └───────────┴───────────┘
                │
           Write-back
           (to Reg File)
```

The CPU is single-cycle: all combinational logic settles within one clock period, and register/memory writes occur on the rising edge.

---

## Status Flags

| Flag | Bit | Set when |
|------|-----|----------|
| Z (Zero) | 0 | Result == 0 |
| C (Carry) | 1 | Unsigned arithmetic overflow |
| N (Negative) | 2 | Result MSB == 1 |
| V (Overflow) | 3 | Signed arithmetic overflow |

Flags are only updated by instructions that set them (see instruction table above). Logic operations (NOR, AND, XOR) set Z, C, N, V; RSH, LDI, JMP, BRH, CAL, RET, LOD, STR do not.
