`timescale 1ns / 1ps


module ooo_core_top (

    //----------------------------------
    // Clock / Reset
    //----------------------------------
    input logic clk,
    input logic reset,
    output logic commit_valid0_out,
    output logic commit_valid1_out,
    output logic [4:0] commit_rd0_out,
    output logic [4:0] commit_rd1_out,
    output logic [5:0] commit_prd0_output,
    output logic [5:0] commit_prd1_output,
    output logic [31:0] result_integer
);

parameter ADDR_W = 32;
parameter PHYS_REG = 6;
parameter MICRO_OP = 5;
parameter ARCH_REG = 5;
//==========================================================
// PROPAGATED/PIPELINED Signals
//==========================================================

//----------------------------------
// Declarations
//----------------------------------

logic redirect_valid_if;
logic [ADDR_W-1:0] redirect_pc_if;
logic [ADDR_W-1:0] pc_from_if, pc_to_jal;
logic [ADDR_W-1:0] inst_from_inst_mem;
logic jal_valid;
logic [ADDR_W-1:0] jal_target_to_if;
logic valid_to_jal_fl, valid_from_if;
logic [ADDR_W-1:0] inst_to_rat;

logic [PHYS_REG-1:0] prs1_to_issue;
logic [PHYS_REG-1:0] prs2_to_issue;
logic [PHYS_REG-1:0] prd_to_issue;
logic [PHYS_REG-1:0] free_pr_to_rat;
logic validFree_to_rat;
logic [ADDR_W-1:0] inst_to_issue;
logic needs_imm;
logic needs_imm_to_rs;
logic [MICRO_OP-1:0] micro_op_to_rs;
logic int_rs_we, branch_rs_we;
logic [PHYS_REG-1:0] rs_prs1, rs_prs2, rs_prd;
logic prs1_ready, prs2_ready;

logic [ADDR_W-1:0] pc_to_rat;
logic [ADDR_W-1:0] pc_to_issue;
logic [ADDR_W-1:0] pc_to_rs;

logic needs_pc, need_pc_to_ex;


logic [ADDR_W-1:0] imm_to_rs;

logic        issue_we_integer;
logic        issue_we_integer_pr;

logic [2:0]  issue_idx_integer;
logic [2:0]  issue_idx_integer_pr;

logic [4:0]  issue_micro_op_integer;
logic [4:0]  issue_micro_op_integer_pr;

logic [5:0]  issue_prs1_integer;
logic [5:0]  issue_prs1_integer_pr;

logic [5:0]  issue_prs2_integer;
logic [5:0]  issue_prs2_integer_pr;

logic [5:0]  issue_prd_integer;
logic [5:0]  issue_prd_integer_pr;

logic        issue_prs1_ready_integer;
logic        issue_prs1_ready_integer_pr;

logic        issue_prs2_ready_integer;
logic        issue_prs2_ready_integer_pr;

logic        issue_uses_imm_integer;
logic        issue_uses_imm_integer_pr;

logic        issue_uses_pc_integer;
logic        issue_uses_pc_integer_pr;

logic [31:0] issue_imm_integer;
logic [31:0] issue_imm_integer_pr;

logic [31:0] issue_pc_integer;
logic [31:0] issue_pc_integer_pr;



logic        issue_we_branch;
logic        issue_we_branch_pr;

logic [2:0]  issue_idx_branch;
logic [2:0]  issue_idx_branch_pr;

logic [4:0]  issue_micro_op_branch;
logic [4:0]  issue_micro_op_branch_pr;

logic [5:0]  issue_prs1_branch;
logic [5:0]  issue_prs1_branch_pr;

logic [5:0]  issue_prs2_branch;
logic [5:0]  issue_prs2_branch_pr;

logic [5:0]  issue_prd_branch;
logic [5:0]  issue_prd_branch_pr;

logic        issue_prs1_ready_branch;
logic        issue_prs1_ready_branch_pr;

logic        issue_prs2_ready_branch;
logic        issue_prs2_ready_branch_pr;

logic        issue_uses_imm_branch;
logic        issue_uses_imm_branch_pr;

logic        issue_uses_pc_branch;
logic        issue_uses_pc_branch_pr;

logic [31:0] issue_imm_branch;
logic [31:0] issue_imm_branch_pr;

logic [31:0] issue_pc_branch;
logic [31:0] issue_pc_branch_pr;

logic issue_we_branch_ex;
logic issue_we_integer_ex;

logic [ADDR_W-1:0] issue_op_a_integer_pr;
logic [ADDR_W -1:0] issue_op_b_integer_pr;

logic [ADDR_W-1:0] issue_op_a_branch_pr;
logic [ADDR_W -1:0] issue_op_b_branch_pr;

logic cdb_broadcast_integer_valid;
logic [ADDR_W-1:0] cdb_broadcast_integer_result;
logic [PHYS_REG-1:0] cdb_broadcast_integer_prd;

logic cdb_broadcast_branch_valid;
logic cdb_broadcast_branch_taken;
logic [ADDR_W-1:0] cdb_broadcast_branch_target;
logic [PHYS_REG-1:0] cdb_broadcast_branch_prd;
logic cdb_integer_valid;

logic [ADDR_W-1:0]     cdb_integer_result;
logic [PHYS_REG-1:0]   cdb_integer_prd;

logic cdb_branch_valid;
logic [5:0] cdb_branch_prd;
logic cdb_branch_taken;
//logic [PHYS_REG-1:0]   cdb_intege_prd;
logic commit_valid0;
logic commit_valid1;
logic [ARCH_REG-1:0] commit_rd0;
logic [PHYS_REG-1:0] commit_prd0;
logic [PHYS_REG-1:0] commit_prd0_old;
logic [PHYS_REG-1:0] commit_prd1_old;
logic [ARCH_REG-1:0] commit_rd1;
logic [PHYS_REG-1:0] commit_prd1;

logic [PHYS_REG-1:0] old_prd_in;
logic [15:0] free_valid;
logic [PHYS_REG-1:0] freePR [15:0];
logic valid_to_busy_list;
logic ready_out;
logic ready_out_branch;
logic issue_valid_branch;
logic issue_valid_integer;
logic issue_valid_integer_ex;
logic [PHYS_REG-1:0] old_prd_to_issue;
logic [PHYS_REG-1:0] old_prd_to_rob;

always_ff @(posedge clk) begin
    if(reset) begin
        pc_to_jal <= 32'h0000_0000;
        valid_to_jal_fl <= 1'b0;
        issue_we_integer_pr <= 1'b0;
        issue_we_integer <= 1'b0;
        issue_idx_integer_pr <= '0;
        issue_micro_op_integer_pr <= '0;
        issue_prs1_integer_pr <= '0;
        issue_prs2_integer_pr <= '0;
        issue_prd_integer_pr <= '0;
        issue_prs1_ready_integer_pr <= 1'b0;
        issue_prs2_ready_integer_pr <= 1'b0;
        issue_uses_imm_integer_pr <= 1'b0;
        issue_uses_pc_integer_pr <= 1'b0;
        //issue_uses_pc_integer <= 1'b0;
        issue_imm_integer_pr <= '0;
        issue_pc_integer_pr <= '0;
        //issue_pc_integer <= '0;
        //cdb_broadcast_branch_prd <= '0;
        issue_valid_integer_ex <= 0;
        issue_we_branch_pr <= 1'b0;
        issue_idx_branch_pr <= '0;
        issue_micro_op_branch_pr <= '0;
        issue_prs1_branch_pr <= '0;
        issue_prs2_branch_pr <= '0;
        issue_prd_branch_pr <= '0;
        issue_prs1_ready_branch_pr <= 1'b0;
        issue_prs2_ready_branch_pr <= 1'b0;
        issue_uses_imm_branch_pr <= 1'b0;
        issue_uses_pc_branch_pr <= 1'b0;
        issue_imm_branch_pr <= '0;
        issue_pc_branch_pr <= '0;

        issue_we_branch_ex <= 1'b0;
        issue_we_integer_ex <= 1'b0;
        need_pc_to_ex <= 1'b0;

        inst_to_issue <= '0;
        inst_to_rat <= '0;
        needs_imm_to_rs <= '0;
        pc_to_issue <= '0;
        pc_to_rat <= '0;
        pc_to_rs <= '0;
        issue_we_branch <= '0;
        commit_rd0_out     <= '0;
        commit_rd1_out     <= '0;
        commit_prd0_output <= '0;
        commit_prd1_output <= '0;
        commit_valid0_out <= 0;
        commit_valid1_out <= 0;
        valid_to_busy_list <= 0;

        old_prd_to_rob <= 0;
        result_integer <= '0;
        
    end else begin
        pc_to_jal <= pc_from_if;
        pc_to_rat <= pc_from_if;
        pc_to_issue <= pc_to_rat;
        pc_to_rs <= pc_to_issue;
        valid_to_jal_fl <= valid_from_if;
        inst_to_rat <= inst_from_inst_mem;
        inst_to_issue <= inst_to_rat;
        needs_imm_to_rs <= needs_imm;

        issue_we_integer_pr <= issue_we_integer;
        issue_idx_integer_pr <= issue_idx_integer;
        issue_micro_op_integer_pr <= issue_micro_op_integer;
        issue_prs1_integer_pr <= issue_prs1_integer;
        issue_prs2_integer_pr <= issue_prs2_integer;
        issue_prd_integer_pr <= issue_prd_integer;
        issue_prs1_ready_integer_pr <= issue_prs1_ready_integer;
        issue_prs2_ready_integer_pr <= issue_prs2_ready_integer;
        issue_uses_imm_integer_pr <= issue_uses_imm_integer;
        issue_uses_pc_integer_pr <= issue_uses_pc_integer;
        issue_imm_integer_pr <= issue_imm_integer;
        issue_pc_integer_pr <= issue_pc_integer;


        issue_we_branch_pr <= issue_we_branch;
        issue_idx_branch_pr <= issue_idx_branch;
        issue_micro_op_branch_pr <= issue_micro_op_branch;
        issue_prs1_branch_pr <= issue_prs1_branch;
        issue_prs2_branch_pr <= issue_prs2_branch;
        issue_prd_branch_pr <= issue_prd_branch;
        issue_prs1_ready_branch_pr <= issue_prs1_ready_branch;
        issue_prs2_ready_branch_pr <= issue_prs2_ready_branch;
        issue_uses_imm_branch_pr <= issue_uses_imm_branch;
        issue_uses_pc_branch_pr <= issue_uses_pc_branch;
        issue_imm_branch_pr <= issue_imm_branch;
        issue_pc_branch_pr <= issue_pc_branch;

        issue_we_branch_ex <= issue_we_branch;
        issue_we_integer_ex <= issue_we_integer;
        need_pc_to_ex <= needs_pc;
        commit_valid0_out  <= commit_valid0;
        commit_valid1_out  <= commit_valid1;

        commit_rd0_out     <= commit_rd0;
        commit_prd0_output <= commit_prd0;

        commit_rd1_out     <= commit_rd1;
        commit_prd1_output <= commit_prd1;
        valid_to_busy_list <= validFree_to_rat;
        issue_valid_integer_ex <= issue_valid_integer;
        old_prd_to_rob <= old_prd_to_issue;
        result_integer <= cdb_broadcast_integer_result;
    end
end

//==========================================================
// FRONT END
//==========================================================

//----------------------------------
// Instruction Fetch
//----------------------------------

inst_fetch u_inst_fetch (
    .clk                 (clk),
    .reset               (reset),

    //----------------------------------
    // Branch redirect from execution
    //----------------------------------
    .redirect_valid      (redirect_valid_if),
    .redirect_pc         (redirect_pc_if),

    .jump_valid          (jal_valid),
    .jump_address        (jal_target_to_if),


    //----------------------------------
    // Outputs to Decode
    //----------------------------------
    .pc                  (pc_from_if),
    .valid               (valid_from_if)
);


inst_memory u_inst_memory (

    .clk         (clk),
    .reset       (reset),
    .valid       (valid_from_if),
    .pc          (pc_from_if),

    .instruction (inst_from_inst_mem)

);


//----------------------------------
// JAL Early Redirect
//----------------------------------
jal_detect u_jal_detect (
    .valid_in   (valid_to_jal_fl),

    .instruction(inst_from_inst_mem),
    .pc         (pc_to_jal),

    .jal_valid  (jal_valid),
    .jal_target (jal_target_to_if)
);


//==========================================================
// DECODE
//==========================================================


//==========================================================
// RENAME / DISPATCH / DECODE
//==========================================================

//----------------------------------
// Physical Register Free List
//----------------------------------
freeList u_freeList (
    .clk                    (clk),
    .reset                  (reset),

    //----------------------------------
    // Request next free physical register
    //----------------------------------
    .needNextFree            (valid_to_jal_fl),

    //----------------------------------
    // Free list inputs
    //----------------------------------
    .freePRin                (freePR),
    .free_valid              (free_valid),

    //----------------------------------
    // Retired physical registers to free
    //----------------------------------
    .free_retired_valid1     (commit_valid0),
    .free_retired_valid2     (commit_valid1),

    .free_retired_PR1        (commit_prd0_old),
    .free_retired_PR2        (commit_prd1_old),

    //----------------------------------
    // Output next free physical register
    //----------------------------------
    .freePR                  (free_pr_to_rat),
    .validFree           (validFree_to_rat)
);



registerAliasTable u_registerAliasTable (
    .clk          (clk),
    .rst          (reset),
    .flush        (),

    //----------------------------------
    // Architectural inputs
    //----------------------------------
    .rs1     (inst_to_rat[19:15]),
    .rs2     (inst_to_rat[24:20]),
    .rd      (inst_to_rat[11:7]),
    .opcode  (inst_to_rat[6:0]),

    .branch_prd   (),
    .branch_taken (),

    //----------------------------------
    // Free list provides new physical register for rd
    //----------------------------------
    .free_prd     (free_pr_to_rat),

    //----------------------------------
    // Outputs (renamed physical registers)
    //----------------------------------
    .prs1         (prs1_to_issue),
    .prs2         (prs2_to_issue),
    .prd          (prd_to_issue),
    .old_prd       (old_prd_to_issue),
    .needs_imm     (needs_imm)
);


//----------------------------------
// Immediate Extension
//----------------------------------
imm_extend u_imm_extend (
    .clk         (clk),
    .reset       (reset),

    //----------------------------------
    // Decode inputs
    //----------------------------------
    .instruction (inst_to_issue),
    .imm_needed  (needs_imm),

    //----------------------------------
    // Output to Rename / Dispatch
    //----------------------------------
    .imm         (imm_to_rs)
);

logic we_rename_to_rob;
logic [ARCH_REG-1: 0] rename_to_rob_rd;
logic [PHYS_REG-1: 0] rename_to_rob_prd;
//----------------------------------
// Rename / Issue Logic
//----------------------------------
rename_issue u_rename_issue (
    .clk             (clk),
    .reset           (reset),
    .valid          (valid_to_busy_list),
    //----------------------------------
    // From RAT / Rename stage
    //----------------------------------
    .opcode          (inst_to_issue[6:0]),
    .instruction      (inst_to_issue),
    .prs1            (prs1_to_issue),
    .prs2            (prs2_to_issue),
    .prd             (prd_to_issue),

    .arch_rd         (inst_to_issue[11:7]),
    .branch_tag_in   (),

    //----------------------------------
    // ROB interface
    //----------------------------------
    .rob_we          (we_rename_to_rob),
    .rob_rd          (rename_to_rob_rd),
    .rob_prd         (rename_to_rob_prd),

    //----------------------------------
    // Integer enable + source/dest physical registers
    //----------------------------------
    .int_rs_we       (int_rs_we),

    .rs_prs1         (rs_prs1),
    .rs_prs2         (rs_prs2),
    .rs_prd          (rs_prd),

    //----------------------------------
    // Load/Store RS
    //----------------------------------
    .ls_rs_we        (),

    //----------------------------------
    // Branch RS
    //----------------------------------
    .branch_rs_we    (branch_rs_we),
    .branch_tag_out  (),
    .micro_op_out    (micro_op_to_rs),
    .needs_pc       (needs_pc)
);


busy_table busy_table_inst (
    .clk            (clk),
    .reset          (reset),
    

    .prd_valid      (valid_to_busy_list),
    .prd            (prd_to_issue),

    .prs1           (prs1_to_issue),
    .prs2           (prs2_to_issue),

    .freeprs1_valid (cdb_broadcast_integer_valid),
    .freeprs1       (cdb_broadcast_integer_prd),

    .freeprs2_valid (cdb_branch_valid),
    .freeprs2       (cdb_branch_prd),

    .prs1_ready     (prs1_ready),
    .prs2_ready     (prs2_ready)
);

//logic prs1_ready_in;
//logic prs2_ready_in;

//==========================================================
// SCHEDULING
//==========================================================

//----------------------------------
// Integer Reservation Station
//----------------------------------
rs_integer u_rs_integer (
    .clk                 (clk),
    .reset               (reset),

    //----------------------------------
    // Write (issue stage → RS)
    //----------------------------------
    .rs_we               (int_rs_we),

    .micro_op            (micro_op_to_rs),

    .prs1                (rs_prs1),
    .prs2                (rs_prs2),
    .prd                 (rs_prd),

    .prs1_ready          (prs1_ready),
    .prs2_ready          (prs2_ready),

    .uses_imm            (needs_imm_to_rs),
    .uses_pc             (needs_pc),
    .imm                 (imm_to_rs),
    .pc                  (pc_to_rs),

    .free_valid       (free_valid),
    .freePRin          (freePR),
    //----------------------------------
    // Read / issue to ALU
    //----------------------------------
    .issue_we            (ready_out),

    .issue_idx           (),

    .issue_micro_op      (issue_micro_op_integer),
    .issue_prs1          (issue_prs1_integer),
    .issue_prs2          (issue_prs2_integer),
    .issue_prd           (issue_prd_integer),

    .issue_prs1_ready    (issue_prs1_ready_integer),
    .issue_prs2_ready    (issue_prs2_ready_integer),

    .issue_uses_imm      (issue_uses_imm_integer),
    .issue_uses_pc       (issue_uses_pc_integer),
    .issue_imm           (issue_imm_integer),
    .issue_pc            (issue_pc_integer),

    .issue_valid         (issue_valid_integer),
    //----------------------------------
    // Wakeup (from CDB / execution result)
    //----------------------------------
    .cdb_valid1          (cdb_broadcast_integer_valid),
    .cdb_prd1            (cdb_broadcast_integer_prd),

    .cdb_valid2          (cdb_broadcast_branch_valid),
    .cdb_prd2            (cdb_broadcast_branch_prd  )
);


//----------------------------------
// Branch Reservation Station
//----------------------------------
rs_branch u_rs_branch (
    .clk                 (clk),
    .reset               (reset),

    //----------------------------------
    // Write (issue stage → RS)
    //----------------------------------
    .rs_we               (branch_rs_we),

    .micro_op            (micro_op_to_rs),

    .prs1                (rs_prs1),
    .prs2                (rs_prs2),
    .prd                 (rs_prd),

    .prs1_ready          (prs1_ready),
    .prs2_ready          (prs2_ready),

    .uses_imm            (needs_imm_to_rs),
    .imm                 (imm_to_rs),
    .pc                  (pc_to_rs),

    .free_valid       (free_valid),
    .freePRin          (freePR),
    //----------------------------------
    // Read / issue to ALU
    //----------------------------------
    .issue_we            (ready_out_branch),

    .issue_idx           (),

    .issue_micro_op      (issue_micro_op_branch),
    .issue_prs1          (issue_prs1_branch),
    .issue_prs2          (issue_prs2_branch),
    .issue_prd           (issue_prd_branch),

    .issue_prs1_ready    (issue_prs1_ready_branch),
    .issue_prs2_ready    (issue_prs2_ready_branch),

    .issue_uses_imm      (issue_uses_imm_branch),
    .issue_imm           (issue_imm_branch),
    .issue_pc            (issue_pc_branch),

    .issue_valid         (issue_valid_branch),
    //----------------------------------
    // Wakeup (from CDB / execution result)
    //----------------------------------
    .cdb_valid1          (cdb_broadcast_integer_valid),
    .cdb_prd1            (cdb_broadcast_integer_prd),

    .cdb_valid2          (cdb_broadcast_branch_valid),
    .cdb_prd2            (cdb_broadcast_branch_prd  )
);

//----------------------------------
// Physical Register File
//----------------------------------
physical_regfile u_physical_regfile (
    .clk                (clk),
    .reset              (reset),

    //----------------------------------
    // 6 READ PORTS
    //----------------------------------
    .active_integer     (issue_valid_integer),
    .active_branch      (issue_valid_branch),
    .active_load_store  (),

    .raddr0             (issue_prs1_integer),
    .raddr1             (issue_prs2_integer),
    .raddr2             (issue_prs1_branch),
    .raddr3             (issue_prs2_branch),
    .raddr4             (),
    .raddr5             (),

    .rdata0             (issue_op_a_integer_pr),
    .rdata1             (issue_op_b_integer_pr),
    .rdata2             (issue_op_a_branch_pr),
    .rdata3             (issue_op_b_branch_pr),
    .rdata4             (),
    .rdata5             (),

    .we0        (cdb_broadcast_integer_valid),
    .waddr0     (cdb_broadcast_integer_prd),
    .wdata0     (cdb_broadcast_integer_result),

    .we1        (cdb_branch_valid),
    .waddr1     (cdb_broadcast_branch_prd),
    .wdata1     (cdb_broadcast_branch_target)
);



//==========================================================
// EXECUTION
//==========================================================

//----------------------------------
// Integer Execution Unit
//----------------------------------
exec_unit_integer u_exec_unit_integer (
    .clk          (clk),
    .reset        (reset),

    //----------------------------------
    // From Reservation Station
    //----------------------------------
    .valid_in     (issue_valid_integer_ex),

    .micro_op     (issue_micro_op_integer_pr),

    .prs1         (issue_prs1_integer_pr),
    .prs2         (issue_prs2_integer_pr),
    .prd          (issue_prd_integer_pr),

    .op_a         (issue_op_a_integer_pr),
    .op_b         (issue_op_b_integer_pr),
    .imm          (issue_imm_integer_pr),
    .pc           (issue_pc_integer_pr),

    .uses_imm     (issue_uses_imm_integer_pr),
    .uses_pc      (need_pc_to_ex),

    //----------------------------------
    // Pipeline control
    //----------------------------------
    .ready_out    (ready_out),

    //----------------------------------
    // To CDB (writeback)
    //----------------------------------
    .cdb_valid    (cdb_integer_valid),
    .cdb_prd      (cdb_integer_prd),
    .cdb_result   (cdb_integer_result)
);



//----------------------------------
// Branch Execution Unit
//----------------------------------
exec_unit_branch u_exec_unit_branch (
    .clk             (clk),
    .reset           (reset),

    //----------------------------------
    // From RS
    //----------------------------------
    .valid_in        (issue_valid_branch),

    .micro_op        (issue_micro_op_branch_pr),

    .prs1            (issue_prs1_branch_pr),
    .prs2            (issue_prs2_branch_pr),
    .prd             (issue_prd_branch_pr),

    .op_a            (issue_op_a_branch_pr),
    .op_b            (issue_op_b_branch_pr),
    .imm             (issue_imm_branch_pr),
    .pc              (issue_pc_branch_pr),

    //----------------------------------
    // Outputs
    //----------------------------------
    .ready_out       (ready_out_branch),

    .cdb_valid       (cdb_branch_valid),
    .cdb_prd         (cdb_branch_prd    ),

    .redirect_valid  (redirect_valid_if),
    .redirect_pc     (redirect_pc_if)
    //.taken           (cdb_branch_taken)
);


//==========================================================
// WRITEBACK
//==========================================================

//----------------------------------
// Common Data Bus
//----------------------------------
cdb u_cdb (
    .clk                 (clk),
    .reset               (reset),

    //----------------------------------
    // Integer execution completion input
    //----------------------------------
    .integer_valid       (cdb_integer_valid),
    .integer_result      (cdb_integer_result),
    .integer_prd         (cdb_integer_prd),

    //----------------------------------
    // Branch completion input
    //----------------------------------
    .branch_valid        (cdb_branch_valid),
    .branch_taken        (redirect_valid_if),
    .branch_target       (redirect_pc_if),
    .branch_prd          (cdb_branch_prd),
    
    //----------------------------------
    // Broadcast Flush
    //----------------------------------
    

    //----------------------------------
    // Integer CDB register writeback broadcast
    //----------------------------------
    .cdb_integer_valid   (cdb_broadcast_integer_valid),
    .cdb_integer_result  (cdb_broadcast_integer_result),
    .cdb_integer_prd     (cdb_broadcast_integer_prd),

    //----------------------------------
    // Branch resolution broadcast
    //----------------------------------
    .cdb_branch_valid    (cdb_broadcast_branch_valid),
    .cdb_branch_taken    (cdb_broadcast_branch_taken),
    .cdb_branch_target   (cdb_broadcast_branch_target),
    .cdb_branch_prd_out  (cdb_broadcast_branch_prd)
);

logic [3:0] rob_idx_out;

//==========================================================
// COMMIT
//==========================================================

//----------------------------------
// Reorder Buffer
//----------------------------------
reorder_buffer u_reorder_buffer (
    .clk              (clk),
    .reset            (reset),

    //--------------------------------------------------
    // Allocate (Rename Stage)
    //--------------------------------------------------
    .alloc_we         (we_rename_to_rob),

    .micro_op         (),

    .rd               (rename_to_rob_rd),

    .prd              (rename_to_rob_prd),

    .is_branch        (branch_rs_we),

    .rob_idx          (),

    .old_prd          (old_prd_to_rob),
    //--------------------------------------------------
    // Integer Completion (CDB)
    //--------------------------------------------------
    .integer_valid    (cdb_broadcast_integer_valid),
    .integer_prd      (cdb_broadcast_integer_prd),

    //--------------------------------------------------
    // Branch Completion
    //--------------------------------------------------
    .branch_valid     (cdb_broadcast_branch_valid),
    .branch_taken     (cdb_broadcast_branch_taken),
    .branch_prd       (cdb_broadcast_branch_prd),
    .branch_rob_idx   (),

    //--------------------------------------------------
    // Commit (2-wide)
    //--------------------------------------------------
    .commit_valid0    (commit_valid0),
    .commit_valid1    (commit_valid1),

    .commit_rd0       (commit_rd0),
    .commit_prd0      (commit_prd0),

    .commit_rd1       (commit_rd1),
    .commit_prd1      (commit_prd1),

    .commit_prd0_old      (commit_prd0_old),
    .commit_prd1_old      (commit_prd1_old),
    //--------------------------------------------------
    // ROB Status
    //--------------------------------------------------
    .rob_empty        (),
    .rob_full         (),

    //--------------------------------------------------
    // Free List Recovery
    //--------------------------------------------------
    .free_valid       (free_valid),
    .free_pr          (freePR)
);




endmodule
