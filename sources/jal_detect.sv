`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2026 11:18:53 AM
// Design Name: 
// Module Name: jal_detect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module jal_detect(

    input logic        valid_in,

    input logic [31:0] instruction,
    input logic [31:0] pc,

    output logic       jal_valid,
    output logic [31:0] jal_target

);


logic [31:0] jal_imm;


always_comb begin

    //----------------------------------
    // Default outputs
    //----------------------------------

    jal_valid  = 1'b0;
    jal_target = 32'b0;

    jal_imm = {{11{instruction[31]}},
               instruction[31],
               instruction[19:12],
               instruction[20],
               instruction[30:21],
               1'b0};

    //----------------------------------
    // Detect JAL opcode
    //----------------------------------

    if(valid_in && instruction[6:0] == 7'b1101111) begin

        jal_valid  = 1'b1;
        jal_target = pc + jal_imm;

    end

end


endmodule
