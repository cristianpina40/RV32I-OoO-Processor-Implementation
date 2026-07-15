`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2026 11:52:04 PM
// Design Name: 
// Module Name: freeList
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


module freeList #(PHYS_REGS = 6)(

    input  logic clk,
    input  logic reset,

    // request next free physical register
    input  logic needNextFree,
    // free list inputs (up to 3 frees per cycle)
    input logic [PHYS_REGS-1:0] freePRin [15:0],

    // one-hot valid mask for frees
    input  logic [15:0] free_valid,
    input logic free_retired_valid1,
    input logic free_retired_valid2,
    input logic [PHYS_REGS-1:0] free_retired_PR1,
    input logic [PHYS_REGS-1:0] free_retired_PR2,
    // output next free physical register
    output logic [PHYS_REGS-1:0] freePR,
    output logic       validFree

    // debug
  //  output logic [63:0] free_bitmap

);
    logic validNextFree;
    integer i;

    // ---------------------------------
    // Free list bitmap (1 = free, 0 = used)
    // ---------------------------------
    logic [63:0] free;
    logic [63:0] next_free;
    logic [PHYS_REGS-1:0] nextFreePR;

    // ---------------------------------
    // Sequential update
    // ---------------------------------
    always_ff @(posedge clk) begin

        if (reset) begin
            free <= 64'hFFFF_FFFF_0000_0000; // all registers free at start
            validFree <= 1'b0;
        end
        else begin

            free <= next_free;
            freePR <= nextFreePR;
            validFree <= validNextFree;
        end
    end
    // ---------------------------------
    // Find next free register (priority encoder)
    // ---------------------------------
    
    always_comb begin 
        next_free = free;
        validNextFree = 1'b0;
        nextFreePR = 6'b0;
        // Mark freed registers as free
        for (int i = 0; i < 16; i++) begin
         if (free_valid[i])
            next_free[freePRin[i]] = 1'b1;
        end
        if(free_retired_valid1)
            next_free[free_retired_PR1] = 1'b1;
           
          if(free_retired_valid2)
            next_free[free_retired_PR2] = 1'b1; 
        // If we need a new free register, find the lowest index that is free
        if (needNextFree) begin
            validNextFree = 1'b0;
          
            for (i = 0; i < 64; i++) begin
                if (free[i]) begin
                    nextFreePR = i[5:0]; // output the index of the free register
                    validNextFree = 1'b1;
                    next_free[i] = 1'b0; // mark it as now allocated
                    break; // stop after finding the first free register

                end
                else begin
            validNextFree = 1'b0;
        end
        end

    end
    end


    // debug output
   // assign free_bitmap = free;

endmodule
