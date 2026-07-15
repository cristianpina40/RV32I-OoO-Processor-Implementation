`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/27/2025 03:04:45 PM
// Design Name: 
// Module Name: registerAliasTable
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////


module registerAliasTable #(
    parameter ARCH_REGS = 32,
    //parameter PHYS_REGS = 64,
    parameter PREG_W     = 6,
    parameter REG_W     = 5
)(
    input  logic                 clk,
    input  logic                 rst,
    input logic                  flush,
    // Architectural inputs
    input  logic [REG_W-1:0]     rs1,
    input  logic [REG_W-1:0]     rs2,
    input  logic [REG_W-1:0]     rd,
    input  logic [6:0]           opcode,
    
    input logic [REG_W-1: 0]    branch_prd,
    input logic                 branch_taken,

    // Free list provides new physical register for rd
    input  logic [PREG_W-1:0]     free_prd,

    // Outputs (renamed physical registers)
    output logic [PREG_W-1:0]     prs1,
    output logic [PREG_W-1:0]     prs2,
    output logic [PREG_W-1:0]     prd,
    output logic                 needs_imm,
    output logic [PREG_W-1:0]     old_prd
    //output logic [6:0]           branch_tag_out,

    //input logic free_branch_tag_valid,
    //input logic [6:0] free_branch_tag
);

logic [PREG_W-1:0] rat [31:0];
logic [PREG_W-1:0] next_rat [31:0];
/*******************************
logic [6:0] branch_tag [7:0];
logic [6:0] next_branch_tag [7:0];
logic [7:0] branch_tag_free_list;
logic [7:0] next_branch_tag_free_list;


logic [6:0] next_branch_tag_out;
*******************************/
logic [PREG_W-1:0] next_prs1;
logic [PREG_W-1:0] next_prs2;
logic [PREG_W-1:0] next_prd;
logic next_needs_imm;

logic [PREG_W-1:0] next_old_prd;     

int i;

always_ff @(posedge clk) begin
    if (rst) begin
        prs1 <= 0;
        prs2 <= 0;
        prd  <= 0;
        needs_imm <= 0;
        old_prd <= '0;
        //branch_tag_out <= 0;
            for (i = 0; i <= ARCH_REGS-1; i++) begin
                rat[i] <= i[PREG_W-1:0]; // Initially, architectural reg maps to same physical reg (truncate index to REG_W bits)
            end
            /*
            for (i = 0; i < 8; i++) begin
                branch_tag[i] <= 64 + i;
                branch_tag_free_list[i] <= 1'b1; // All branch tags start as free
            end
            */
    end 
    else if ((branch_taken | flush) & !rst) begin
        prs1 <= 0;
        prs2 <= 0;
        prd  <= 0;
        rat <= rat;
        needs_imm <= 0;
        old_prd <= '0;
       end
    
    else begin
        // For source registers, output the current mapping (could be from a previous instruction)
        prs1 <= next_prs1;
        prs2 <= next_prs2;
        // For destination register, assign a new physical register if writing
        prd  <= next_prd;
        // Update the RAT for the destination register
        rat <= next_rat;
        needs_imm <= next_needs_imm;
        old_prd <= next_old_prd;
        /*********
        branch_tag <= next_branch_tag;
        branch_tag_free_list <= next_branch_tag_free_list;
        branch_tag_out <= next_branch_tag_out;
        ***********/
    end
end
/*****************
always_comb begin 
    next_branch_tag_free_list = branch_tag_free_list; // Default: no change to free list
    next_branch_tag = branch_tag; // Default: no change to tags 
    if(free_branch_tag_valid) begin
        next_branch_tag_free_list[branch_tag[free_branch_tag]] = 1'b1; // Mark the freed tag as available
    end
    else begin
        next_branch_tag_free_list = branch_tag_free_list; // No change to free list
    end
end
*******************/
always_comb begin

    // -----------------------------
    // SAFE DEFAULTS
    // -----------------------------
    next_prs1 = '0;
    next_prs2 = '0;
    next_prd  = '0;
    next_needs_imm = 1'b0;
    //next_branch_tag_out = '0;

    next_old_prd = rat[rd];
    next_rat = rat; // important: start from current state

    case (opcode)

        // =================================================
        // R-TYPE (OP)
        // =================================================
        7'b0110011: begin
            next_prs1 = rat[rs1];
            next_prs2 = rat[rs2];
            next_prd = free_prd;
            next_rat[rd] = free_prd;
        end

        // =================================================
        // I-TYPE ALU (OP-IMM)
        // =================================================
        7'b0010011: begin
            next_prs1 = rat[rs1];
            next_prd = free_prd;
            next_rat[rd] = free_prd;
            next_needs_imm = 1'b1;
        end

        // =================================================
        // LOAD
        // =================================================
        7'b0000011: begin
            next_prs1 = rat[rs1];
            next_prd = free_prd;
            next_rat[rd] = free_prd;
            next_needs_imm = 1'b1;
        end

        // =================================================
        // STORE (S-TYPE)
        // =================================================
        7'b0100011: begin
            next_prs1 = rat[rs1];
            next_prs2 = rat[rs2];
            next_needs_imm = 1'b1;
            next_prd = free_prd;
        end

        // =================================================
        // BRANCH (B-TYPE)
        // =================================================
        7'b1100011: begin
            next_prs1 = rat[rs1];
            next_prs2 = rat[rs2];
            //next_rat[rd] = free_prd;
            next_needs_imm = 1'b1;
            next_prd = free_prd;

            /**********************
            for (i = 0; i < 8; i++) begin
                if (branch_tag_free_list[i]) begin
                    next_branch_tag_out = branch_tag[i]; // Use the same free physical register as the branch tag for simplicity
                    next_branch_tag_free_list[i] = 1'b0; // Mark this tag as used
                    break;
                end
               
            end
             ***********************/
        end

        // =================================================
        // LUI (U-TYPE)
        // =================================================
        7'b0110111: begin
            next_prd = free_prd;
            next_rat[rd] = free_prd;
            next_needs_imm = 1'b1;
        end

        // =================================================
        // AUIPC (U-TYPE)
        // =================================================
        7'b0010111: begin
            next_prd = free_prd;
            next_rat[rd] = free_prd;
            next_needs_imm = 1'b1;
        end

        // =================================================
        // JAL (J-TYPE)
        // =================================================
        7'b1101111: begin
            next_prd = free_prd;
            next_rat[rd] = free_prd;
            next_needs_imm = 1'b1;
        end

        // =================================================
        // JALR (I-TYPE)
        // =================================================
        7'b1100111: begin
            next_prs1 = rat[rs1];
            next_prd = free_prd;
            next_rat[rd] = free_prd;
            next_needs_imm = 1'b1;
        end

        default: begin
            // nothing changes
        end

    endcase
end
endmodule
