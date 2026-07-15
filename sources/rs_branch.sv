`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2026 01:48:30 PM
// Design Name: 
// Module Name: rs_branch
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


module rs_branch(
 input  logic clk,
    input  logic reset,

    //----------------------------------
    // Write (issue stage → RS)
    //----------------------------------
    input  logic        rs_we,        // write enable (insert new instruction)

    input  logic [4:0]  micro_op,

    input  logic [5:0]  prs1,
    input  logic [5:0]  prs2,
    input  logic [5:0]  prd,

    input  logic        prs1_ready,
    input  logic        prs2_ready,
   
    input  logic        uses_imm,
    input  logic [31:0] imm,
    input  logic [31:0] pc, // Program counter for AUIPC

    input logic [5:0] freePRin [15:0],

   
    input  logic [15:0] free_valid,
    //----------------------------------
    // Read / issue to ALU
    //----------------------------------
    input  logic        issue_we,      // RS → ALU dispatch enable
    output logic [2:0]  issue_idx,     // selected instruction index

    output logic [4:0]  issue_micro_op,
    output logic [5:0]  issue_prs1,
    output logic [5:0]  issue_prs2,
    output logic [5:0]  issue_prd,

    output logic        issue_prs1_ready,
    output logic        issue_prs2_ready,

    output logic        issue_uses_imm,
    output logic [31:0] issue_imm,
    output logic [31:0] issue_pc,

    //----------------------------------
    // Wakeup (from CDB / execution result)
    //----------------------------------
    input  logic        cdb_valid1,
    input  logic [5:0]  cdb_prd1,

    input  logic        cdb_valid2,
    input  logic [5:0]  cdb_prd2,
    output logic issue_valid

);

typedef struct packed {
    
    logic valid_entry_bit; // Indicates if this entry is valid (contains an instruction)

    logic [4:0]  micro_op;

    logic [5:0]  prs1;
    logic [5:0]  prs2;
    logic [5:0]  prd;

    logic        prs1_ready;
    logic        prs2_ready;
    logic [3:0] rob_idx;

    logic        uses_imm;
    logic [31:0] imm;
    logic [31:0] pc; // Program counter for AUIPc

} rs_entry_t;

// 8 reservation station entries
rs_entry_t rs[8];
rs_entry_t next_rs[8];

logic found;
logic found_alu_next;
integer i, y;

logic [2:0]  next_issue_idx;

logic [4:0]  next_issue_micro_op;
logic [5:0]  next_issue_prs1;
logic [5:0]  next_issue_prs2;
logic [5:0]  next_issue_prd;

logic        next_issue_prs1_ready;
logic        next_issue_prs2_ready;

logic        next_issue_uses_imm;
logic [31:0] next_issue_imm;
logic [31:0] next_issue_pc; 

logic next_issue_valid;
logic [5:0]prev_cdb1_in;
logic [5:0]prev_cdb2_in;

logic prev_cdb1_valid;
logic prev_cdb2_valid;
always_ff @(posedge clk) begin
    if (reset) begin
        // Initialize reservation stations to empty
        for (int i = 0; i < 8; i++) begin
            rs[i] <= '0;
        end

        issue_idx        <= '0;
        issue_micro_op   <= '0;

        issue_prs1       <= '0;
        issue_prs2       <= '0;
        issue_prd        <= '0;

        issue_prs1_ready <= '0;
        issue_prs2_ready <= '0;

        issue_uses_imm   <= '0;
        issue_imm        <= '0;
       // found <= 1'b0;
        //found_alu_next <= 1'b0;
        issue_pc       <= '0;
        prev_cdb1_in <= 0;
        prev_cdb2_in <= 0;
        prev_cdb1_valid <= 0;
        prev_cdb2_valid <= 0;
        issue_valid <= 0;
    end else begin
         for (int i = 0; i < 8; i++) begin
            rs[i] <= next_rs[i];
        end

         issue_idx        <= next_issue_idx;
        issue_micro_op   <= next_issue_micro_op;

        issue_prs1       <= next_issue_prs1;
        issue_prs2       <= next_issue_prs2;
        issue_prd        <= next_issue_prd;

        issue_prs1_ready <= next_issue_prs1_ready;
        issue_prs2_ready <= next_issue_prs2_ready;

        issue_uses_imm   <= next_issue_uses_imm;
        issue_imm        <= next_issue_imm;
        //found <= found;
        //found_alu_next <= found_alu_next;
        issue_pc       <= next_issue_pc;

        issue_valid <= next_issue_valid;

        prev_cdb1_in <= cdb_prd1;
        prev_cdb2_in <= cdb_prd2;

         prev_cdb1_valid <= cdb_valid1;
        prev_cdb2_valid <= cdb_valid2;


    end

end



always_comb begin 

     for (int i = 0; i < 8; i++) begin
        next_rs[i] = rs[i];
    end
    //found_alu_next = 1'b0; // Default: not found an instruction to issue
    next_issue_idx        = issue_idx;
    //found = 1'b0;
    next_issue_micro_op   = issue_micro_op;

    next_issue_prs1       = issue_prs1;
    next_issue_prs2       = issue_prs2;
    next_issue_prd        = issue_prd;

    next_issue_prs1_ready = issue_prs1_ready;
    next_issue_prs2_ready = issue_prs2_ready;

    next_issue_uses_imm   = issue_uses_imm;
    next_issue_imm        = issue_imm;
    next_issue_pc = issue_pc;
    next_issue_valid = issue_valid;

    for(i = 0; i < 8; i++)begin
            if(free_valid[i])begin
                for(y = 0; y < 8; y++)begin
                      if((rs[i].prd == freePRin[y]) | (rs[i].prd == freePRin[y+8]))begin
                        next_rs[i].valid_entry_bit = 1'b0;
                    end
                end
            end
        end
        
    // Handle write (inserting a new entry) in combinational next-state
    if (rs_we) begin
    // Insert new instruction into the first available reservation station entry
    for (i = 0; i < 8; i++) begin
        if (!rs[i].valid_entry_bit) begin
            next_rs[i].valid_entry_bit = 1'b1;
            next_rs[i].micro_op        = micro_op;
            next_rs[i].prs1            = prs1;
            next_rs[i].prs2            = prs2;
            next_rs[i].prd             = prd;
            next_rs[i].prs1_ready      = prs1_ready;
            next_rs[i].prs2_ready      = prs2_ready;
            next_rs[i].uses_imm        = uses_imm;
            next_rs[i].imm             = imm;
            next_rs[i].pc              = pc;

            break;
        end
    end
end


// Handle output of next ALU operation when ALU is ready for new instruction (issue_we)
    if (issue_we) begin
    // Find the first ready instruction
        next_issue_valid = 0;
    for (i = 0; i < 8; i++) begin
        if (rs[i].valid_entry_bit && ((rs[i].prs1_ready && rs[i].prs2_ready) | (rs[i].prs1_ready && rs[i].uses_imm))) begin

            next_issue_idx        = i[2:0];
            next_issue_micro_op   = rs[i].micro_op;
            next_issue_prs1       = rs[i].prs1;
            next_issue_prs2       = rs[i].prs2;
            next_issue_prd        = rs[i].prd;
            next_issue_prs1_ready = rs[i].prs1_ready;
            next_issue_prs2_ready = rs[i].prs2_ready;
            next_issue_uses_imm   = rs[i].uses_imm;
            next_issue_imm        = rs[i].imm;
            next_issue_pc         = rs[i].pc;

            next_rs[i].valid_entry_bit = 1'b0;
            next_issue_valid = 1;
            break;
        end
    end
end

// Handle wakeup from CDB 1
if(cdb_valid1) begin
    // Wakeup logic for CDB 1
    for (i = 0; i < 8; i++) begin
        if (rs[i].valid_entry_bit) begin
            if (rs[i].prs1 == cdb_prd1) begin
                next_rs[i].prs1_ready = 1'b1;
            end
            if (rs[i].prs2 == cdb_prd1) begin
                next_rs[i].prs2_ready = 1'b1;
            end
        end
    end
end

// Handle wakeup from CDB 2
if(cdb_valid2) begin
    // Wakeup logic for CDB 2
    for (i = 0; i < 8; i++) begin
        if (rs[i].valid_entry_bit) begin
            if (rs[i].prs1 == cdb_prd2) begin
                next_rs[i].prs1_ready = 1'b1;
            end
            if (rs[i].prs2 == cdb_prd2) begin
                next_rs[i].prs2_ready = 1'b1;
            end
        end
    end
end

// Handle wakeup from CDB 1
if(prev_cdb1_valid) begin
    // Wakeup logic for CDB 1
    for (i = 0; i < 8; i++) begin
        if (rs[i].valid_entry_bit) begin
            if (rs[i].prs1 == prev_cdb1_in) begin
                next_rs[i].prs1_ready = 1'b1;
            end
            if (rs[i].prs2 == prev_cdb1_in) begin
                next_rs[i].prs2_ready = 1'b1;
            end
        end
    end
end

// Handle wakeup from CDB 2
if(prev_cdb2_valid) begin
    // Wakeup logic for CDB 2
    for (i = 0; i < 8; i++) begin
        if (rs[i].valid_entry_bit) begin
            if (rs[i].prs1 == prev_cdb2_in) begin
                next_rs[i].prs1_ready = 1'b1;
            end
            if (rs[i].prs2 == prev_cdb1_in) begin
                next_rs[i].prs2_ready = 1'b1;
            end
        end
    end
end


end



endmodule