`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 11:03:50 PM
// Design Name: 
// Module Name: inst_fetch
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


module inst_fetch #(
    parameter ADDR_W = 32
)(
    input logic clk,
    input logic reset,
    //----------------------------------
    // Branch redirect from execution
    //----------------------------------
    input logic        redirect_valid,
    input logic [31:0] redirect_pc,
    
    input logic        jump_valid,
    input logic [31:0] jump_address,

    //----------------------------------
    // Instruction memory interface
    //----------------------------------
    //----------------------------------
    // Outputs to Decode
    //----------------------------------
   
    output logic [31:0] pc,
    output logic valid

);


logic [31:0] next_pc;


//----------------------------------
// Program Counter
//----------------------------------

always_ff @(posedge clk) begin

    if(reset) begin

        pc <= 32'h00000000;
        valid <= 1'b0;

    end

    else begin

        pc <= next_pc;
        valid <= 1'b1;
    end

end



//----------------------------------
// Next PC Logic
//----------------------------------

always_comb begin

    // Default sequential execution

    next_pc = pc;


    // Branch/JAL/JALR redirect

    if(redirect_valid) begin

        next_pc = redirect_pc;

    end
    else if(jump_valid & !redirect_valid) begin
    
        next_pc = jump_address;

    end
    else begin 
    
        next_pc = pc + 32'd4;
        
    end


end






endmodule
