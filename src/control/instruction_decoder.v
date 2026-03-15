`timescale 1ns/1ps
module instruction_decoder(
    input [15:0] instruction,
    output [2:0] opcode_output,
    output [3:0] field1, field2, field3, 
    output [2:0] instruction_type
);
    wire [3:0] opcode = instruction[15:12];
    wire [2:0] parsed_opcode; 
    wire [2:0] type_string;   

    // Örnek isimleri eklendi ve portlar kendi modüllerine göre düzeltildi
    type_decoder td_inst (
        .OPCODE(opcode),
        .TYPE(type_string)        
    );

    opcode_decoder od_inst (
        .OPCODE(opcode),
        .ALUControSignal(parsed_opcode)
    );

    assign opcode_output = parsed_opcode;
    assign field1 = instruction[11:8];  
    assign field2 = instruction[7:4];
    assign field3 = instruction[3:0];
    assign instruction_type = type_string; 

endmodule