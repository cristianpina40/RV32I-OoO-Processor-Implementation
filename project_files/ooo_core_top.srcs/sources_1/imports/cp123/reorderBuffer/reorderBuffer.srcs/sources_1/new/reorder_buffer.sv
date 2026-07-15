`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Independent
// Engineer: Cristian Pina
// 
// Create Date: 08/18/2025 10:50:34 PM
// Design Name: 
// Module Name: reorder_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A Reorder Buffer for an Out of Order Processor.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module reorder_buffer #(
    parameter ROB_ENTRIES = 16,
    parameter ROB_W       = 4,
    parameter PRD_W       = 6
)(

    input  logic clk,
    input  logic reset,

    //--------------------------------------------------
    // Allocate (Rename Stage)
    //--------------------------------------------------
    input  logic        alloc_we,

    input  logic [4:0]  micro_op,

    input  logic [4:0]  rd,

    //input  logic [PRD_W-1:0] old_prd,
    input  logic [PRD_W-1:0] prd,
    input  logic [PRD_W-1:0] old_prd,

    input  logic        is_branch,

    output logic [ROB_W-1:0] rob_idx,

    //--------------------------------------------------
    // Integer Completion (CDB)
    //--------------------------------------------------
    input  logic        integer_valid,
    input  logic [PRD_W-1:0] integer_prd,
    //input  logic [31:0] integer_result,

    //--------------------------------------------------
    // Branch Completion
    //--------------------------------------------------
    input  logic        branch_valid,
    input  logic        branch_taken,
    input  logic [PRD_W-1:0] branch_prd,
    input  logic [ROB_W-1:0] branch_rob_idx,
    //input  logic [31:0] branch_target,

    //--------------------------------------------------
    // Commit (2-wide)
    //--------------------------------------------------
    output logic        commit_valid0,
    output logic        commit_valid1,

    output logic [PRD_W-1:0] commit_rd0,
    output logic [PRD_W-1:0] commit_prd0,

    output logic [PRD_W-1:0] commit_rd1,
    output logic [PRD_W-1:0] commit_prd1,

    //--------------------------------------------------
    //Old PRD to free_list, busy_list
    //--------------------------------------------------

    
    output logic [PRD_W-1:0] commit_prd0_old,

    
    output logic [PRD_W-1:0] commit_prd1_old,



    //--------------------------------------------------
    // Flush / Recovery
    //--------------------------------------------------
   // output logic        flush_valid,
    //output logic [ROB_W-1:0] flush_rob_idx,

    //output logic        redirect_valid,
    //output logic [31:0] redirect_pc,

    inout logic rob_empty,
    inout logic rob_full,
    //--------------------------------------------------
    // Free List Recovery
    //--------------------------------------------------
    output logic [15:0] free_valid,
    output logic [PRD_W-1:0] free_pr [15:0]

);

typedef struct packed {

    logic valid;
    logic ready;

    logic is_branch;

    logic [4:0] micro_op;

    logic [4:0] rd;

    //logic [PRD_W-1:0] old_prd;
    logic [PRD_W-1:0] prd;
    logic [PRD_W-1:0] old_prd;

    //logic [31:0] value;

} rob_entry_t;

rob_entry_t rob[ROB_ENTRIES];
rob_entry_t next_rob[ROB_ENTRIES];

logic [ROB_W:0] head;
logic [ROB_W:0] tail;

logic [ROB_W:0] next_head;
logic [ROB_W:0] next_tail;

logic [4:0] count;
logic [4:0] next_count;
logic signed [1:0] head_count_branch, next_head_count_branch;
logic signed [1:0] head_count_integer, next_head_count_integer;
logic signed [1:0] tail_count, next_tail_count;

logic        next_commit_valid0;
logic        next_commit_valid1;

logic [PRD_W-1:0] next_commit_rd0;
logic [PRD_W-1:0] next_commit_prd0;

logic [PRD_W-1:0] next_commit_rd1;
logic [PRD_W-1:0] next_commit_prd1;
logic [ROB_W-1:0] next_rob_idx;

logic [15:0] next_free_valid;
logic [PRD_W-1:0] next_free_pr [15:0];

logic [PRD_W-1:0] next_old_prd0;
logic [PRD_W-1:0] next_old_prd1;



// ------------------------------
// Allocate Logic
// ------------------------------
always_ff @(posedge clk) begin

integer i;
    if(reset)begin 
        head <= 0;
        tail <= 0;
        count <= 0;
        rob_idx <= 0;
        commit_valid0 <= 1'b0;
        commit_valid1 <= 1'b0;

        commit_rd0    <= '0;
        commit_prd0   <= '0;

        commit_rd1    <= '0;
        commit_prd1   <= '0;
        free_valid <= '0;
        free_pr    <= '{default: '0};
        commit_prd0_old <= '0;
        commit_prd1_old <= '0;

        for(i=0; i<ROB_ENTRIES; i=i+1) begin
            rob[i].valid <= 0;
            rob[i].ready <= 0;
            rob[i].is_branch <= 0;
            rob[i].micro_op <= 0;
            rob[i].rd <= 0;
            rob[i].old_prd <= '0;
            rob[i].prd <= 0;
         
        end

    end else begin

        head <= next_head;
        tail <= next_tail;
        count <= next_count;
        rob_idx <= next_rob_idx;
        commit_valid0 <= next_commit_valid0;
        commit_valid1 <= next_commit_valid1;

        commit_rd0    <= next_commit_rd0;
        commit_prd0   <= next_commit_prd0;

        commit_rd1    <= next_commit_rd1;
        commit_prd1   <= next_commit_prd1;
        commit_prd0_old <= next_old_prd0;
        commit_prd1_old <= next_old_prd1;
        for(i=0; i<ROB_ENTRIES; i=i+1) begin
            rob[i] <= next_rob[i];
        end
        free_valid <= next_free_valid;
        free_pr    <= next_free_pr;

    end
    
end



always_comb begin

    //========================================================
    // Defaults
    //========================================================
    integer i;
    next_head  = head;
    next_tail  = tail;
    next_count = count;

    next_commit_valid0 = 1'b0;
    next_commit_valid1 = 1'b0;

    next_commit_prd0 = '0;
    next_commit_prd1 = '0;

    next_commit_rd0 = '0;
    next_commit_rd1 = '0;

    next_head_count_integer = 1'b0;
    next_head_count_branch  = 1'b0;


    for (i = 0; i < ROB_ENTRIES; i++) begin
        next_rob[i] = rob[i];

        next_free_valid[i] = 1'b0;
        next_free_pr[i]    = '0;
    end



    //========================================================
    // Branch Flush (Highest Priority)
    //========================================================

    if (branch_valid && branch_taken) begin

        next_tail = (branch_rob_idx + 1) % ROB_ENTRIES;


    for (i = 0; i < ROB_ENTRIES; i++) begin

        // Flush all entries between branch+1 and tail
        if (rob[i].valid &&
            (((branch_rob_idx < tail) &&
              (i > branch_rob_idx) &&
              (i < tail)) ||

             ((branch_rob_idx >= tail) &&
              ((i > branch_rob_idx) ||
               (i < tail))))) begin


            next_rob[i].valid     = 1'b0;
            next_rob[i].ready     = 1'b0;
            next_rob[i].is_branch = 1'b0;
            next_rob[i].micro_op  = '0;
            next_rob[i].rd        = '0;
            next_rob[i].prd       = '0;


            next_free_pr[i]    = rob[i].prd;
            next_free_valid[i] = 1'b1;

            end
        end

    end



    //========================================================
    // Normal ROB Operation
    //========================================================

    else begin


        //====================================================
        // Writeback / Ready Update
        //====================================================

        for (i = 0; i < ROB_ENTRIES; i++) begin

            if (rob[i].valid &&
                !rob[i].ready &&
                integer_valid &&
                (rob[i].prd == integer_prd)) begin

                next_rob[i].ready = 1'b1;

            end
            else if (rob[i].valid &&
                     !rob[i].ready &&
                     branch_valid &&
                     !branch_taken &&
                     (rob[i].prd == branch_prd)) begin

                next_rob[i].ready = 1'b1;

            end

        end



        //====================================================
        // Commit Logic
        //====================================================

        if (rob[head].valid && rob[head].ready) begin


            next_commit_valid0 = 1'b1;
            next_commit_prd0   = rob[head].prd;
            next_commit_rd0    = rob[head].rd;
            next_old_prd0      = rob[head].old_prd;

            next_rob[head].valid = 1'b0;


            next_head_count_integer = 1'b1;

            next_head = (head + 1) % ROB_ENTRIES;

            next_count = next_count - 1;



            if (rob[(head+1)%ROB_ENTRIES].valid &&
                rob[(head+1)%ROB_ENTRIES].ready) begin


                next_commit_valid1 = 1'b1;

                next_commit_prd1 =
                    rob[(head+1)%ROB_ENTRIES].prd;

                next_commit_rd1 =
                    rob[(head+1)%ROB_ENTRIES].rd;

                next_old_prd1 = rob[(head+1)%ROB_ENTRIES].old_prd;

                next_rob[(head+ 1)%ROB_ENTRIES].valid = 1'b0;


                next_head_count_branch = 1'b1;


                next_head =
                    (head + 2) % ROB_ENTRIES;


                next_count = next_count - 1;

            end

        end



        //====================================================
        // Allocation Logic (Lowest Priority)
        //====================================================

        if (alloc_we && !rob_full) begin


            next_rob[tail].valid     = 1'b1;
            next_rob[tail].ready     = 1'b0;
            next_rob[tail].is_branch = is_branch;

            next_rob[tail].micro_op = micro_op;
            next_rob[tail].old_prd = old_prd;
            next_rob[tail].rd  = rd;
            next_rob[tail].prd = prd;


            next_tail =
                (tail + 1) % ROB_ENTRIES;


            next_count = next_count + 1;

        end

    end

end

assign rob_full =
    (head[ROB_W-1:0] == tail[ROB_W-1:0]) &&
    (head[ROB_W] != tail[ROB_W]);

assign rob_empty = (head == tail);

endmodule