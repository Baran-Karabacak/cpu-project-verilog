`timescale 1ns/1ps

module type_decoder(
    input [3:0] OPCODE, // ABCD
    output[2:0] TYPE    //xyz
);
//x=A(BC'D'+B'C) y=ABC+AB'C' z=A'(B+C)+ABC
// n-type: 000
// r-type: 001
// I-type: 010
// d-type: 011
// a-type: 100
// 101, 110, 111 Not Aplicable
// İlk değerler
wire A = OPCODE[3];
wire B = OPCODE[2];
wire C = OPCODE[1];
wire D = OPCODE[0];
// Not'lar
wire Anot = ~A;
wire Bnot = ~B;
wire Cnot = ~C;
wire Dnot = ~D;
// Ara değerler
wire BnotC = Bnot & C;
wire BorC = B | C;
wire ABC = A & B & C;
wire BCnotDnot = B & Cnot & Dnot;
wire ABnotCnot = A & Bnot & Cnot;
wire Xcomplex = BCnotDnot | BnotC;
wire Zcomplex = Anot & BorC;
// Sonuç
wire x = A & Xcomplex;
wire y = ABC | ABnotCnot;
wire z = ABC | Zcomplex; 

assign TYPE = {x,y,z};

endmodule