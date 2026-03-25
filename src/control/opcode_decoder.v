// Decodes the raw opcode and returns ALU Control Signal
// Output: nop: 000 hlt: 001 add: 010, sub: 011, nor: 100, and: 101, xor: 110, rsh 111
// Other batch: ldi: 000 adi: 001 jmp: 010 brh: 011 cal: 100 ret: 101 lod: 110 str: 111
`timescale 1ns/1ps

// Opcode: 4bits nop: 0000 halt: 0001 add: 0010, sub: 0011, nor: 0100, and: 0101, xor: 0110, rsh: 0111
// Other batch LDI: 1000 ADI: 1001 JMP: 1010 BRH: 1011 CAL: 1100 RET: 1101 LOD: 1110 STR: 1111
module opcode_decoder(
    input [3:0] OPCODE,
    output [2:0] ALUControSignal
);
// First input determines which ALU to use. A=0 First, ALU A=1 second ALU
wire A = OPCODE[3];
wire B = OPCODE[2];
wire C = OPCODE[1];
wire D = OPCODE[0];

assign ALUControSignal = {B,C,D};
endmodule
// NEXT STEP mux'u buna göre güncelle. MSB checker ekle ve diğer mux ile decoder'i yaz
