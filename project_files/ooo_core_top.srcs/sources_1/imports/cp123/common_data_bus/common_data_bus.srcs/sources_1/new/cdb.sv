`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 10:29:25 PM
// Design Name: 
// Module Name: cdb
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



module cdb #(
    parameter PHYS_REG_W = 6
)(
    input logic clk,
    input logic reset,

    //----------------------------------
    // Integer execution completion input
    //----------------------------------
    input logic        integer_valid,
    input logic [31:0] integer_result,
    input logic [PHYS_REG_W-1:0] integer_prd,
    //----------------------------------
    // Branch completion input
    //----------------------------------
    input logic        branch_valid,
    input logic        branch_taken,
    input logic [31:0] branch_target,
    input logic [PHYS_REG_W-1:0] branch_prd,
    input logic [PHYS_REG_W-1:0] freePRin [15:0],

    // one-hot valid mask for frees
    input  logic [15:0] free_valid,
    //----------------------------------
    // Broadcast outputs
    //----------------------------------
    output logic [PHYS_REG_W-1:0] freePRout [15:0],
    output  logic [15:0] free_valid_out,
    //----------------------------------
    // Integer CDB register writeback broadcast
    //----------------------------------
    output logic                    cdb_integer_valid,
    output logic [31:0]             cdb_integer_result,
    output logic [PHYS_REG_W-1:0]   cdb_integer_prd,

    // Branch resolution broadcast
    output logic        cdb_branch_valid,
    output logic        cdb_branch_taken,
    output logic [31:0] cdb_branch_target,
    output logic [PHYS_REG_W-1:0] cdb_branch_prd_out

);

integer i;
always_ff @(posedge clk) begin

    if(reset) begin

        cdb_integer_valid          <= 1'b0;
        cdb_integer_result         <= '0;
        cdb_integer_prd            <= '0;

        cdb_branch_valid   <= 1'b0;
        cdb_branch_taken   <= 1'b0;
        cdb_branch_target  <= '0;
        cdb_branch_prd_out <= '0;
        for(i = 0; i < 8; i++)begin 
            freePRout[i] <= '0;
        end
        free_valid_out <= '0;

    end
    else begin

        //----------------------------------
        // Integer Execution -> Integer CDB
        //----------------------------------

        cdb_integer_valid  <= integer_valid;
        cdb_integer_result <= integer_result;
        cdb_integer_prd    <= integer_prd;

        //----------------------------------
        // Branch -> CDB
        //----------------------------------

        cdb_branch_valid  <= branch_valid;
        cdb_branch_taken  <= branch_taken;
        cdb_branch_target <= branch_target;
        freePRout <= freePRin;
        free_valid_out <= free_valid;
        cdb_branch_prd_out <= branch_prd;

    end

end


endmodule