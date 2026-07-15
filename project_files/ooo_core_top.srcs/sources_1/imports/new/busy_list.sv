`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2026 04:56:18 PM
// Design Name: 
// Module Name: busy_list
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


module busy_table #(
    parameter PRF_ENTRIES = 64,
    parameter PRD_W       = 6
)(
    input  logic clk,
    input  logic reset,

    // New destination register allocated during rename
    input  logic             prd_valid,
    input  logic [PRD_W-1:0] prd,

    // Source registers to check
    input  logic [PRD_W-1:0] prs1,
    input  logic [PRD_W-1:0] prs2,

    // Registers becoming ready (CDB writeback)
    input  logic             freeprs1_valid,
    input  logic [PRD_W-1:0] freeprs1,

    input  logic             freeprs2_valid,
    input  logic [PRD_W-1:0] freeprs2,

    output logic prs1_ready,
    output logic prs2_ready
);

    // 1 = busy
    // 0 = ready
    logic [PRF_ENTRIES-1:0] busy;
    logic [PRF_ENTRIES-1:0] next_busy;
    logic next_prs1_ready_check1;
    logic next_prs1_ready_check2;
    
    logic next_prs2_ready_check1;
    logic next_prs2_ready_check2;

    logic next_prs1_ready;
    logic next_prs2_ready;
    
    //integer i;

    always_ff @(posedge clk) begin

        if (reset) begin

            // Architectural registers x0-x31 start ready.
            // Extra physical registers are free/ready initially.
            busy <= '0;
            prs1_ready <= '0;
            prs2_ready <= '0;
        end
        else begin
            if(prd_valid)begin
                busy <= next_busy;
                prs1_ready <= next_prs1_ready;
                prs2_ready <= next_prs2_ready;
            end
            else begin 
                busy <= busy;
                prs1_ready <= next_prs1_ready;
                prs2_ready <= next_prs2_ready;
            end
        end

    end
    
    always_comb begin
    
        next_busy = busy;
        next_prs1_ready_check1 = 0;
        next_prs1_ready_check2 = 0;
        next_prs2_ready_check1 = 0;
        next_prs2_ready_check2 = 0;
        
        next_busy[prd] = 1'b1;
     
        next_prs1_ready_check1 = ~busy[prs1];
        
        next_prs1_ready_check2 = (freeprs1_valid && (freeprs1 == prs1)) || (freeprs2_valid && (freeprs2 == prs1));
            
        next_prs2_ready_check1 = ~busy[prs2];
        
        next_prs2_ready_check2 = (freeprs1_valid && (freeprs1 == prs2)) || (freeprs2_valid && (freeprs2 == prs2));

        next_prs1_ready = next_prs1_ready_check1 || next_prs1_ready_check2;
        next_prs2_ready = next_prs2_ready_check1 || next_prs2_ready_check2;

        if(freeprs1_valid)begin
            next_busy[freeprs1] = 1'b0;
        end

        if(freeprs2_valid)begin
            next_busy[freeprs2] = 1'b0;
        end
end

endmodule