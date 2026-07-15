`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/11/2026 12:55:11 PM
// Design Name: 
// Module Name: rename_issue
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


module rename_issue (

    input  logic clk,
    input  logic reset,

    //----------------------------------
    // From RAT / Rename stage
    //----------------------------------
    input  logic valid,
    input  logic [31:0] instruction,
    input  logic [6:0]  opcode,

    input  logic [5:0]  prs1,
    input  logic [5:0]  prs2,
    input  logic [5:0]  prd,

    input  logic [4:0]  arch_rd,
    input  logic [6:0]  branch_tag_in,

    //----------------------------------
    // Resource status
    //----------------------------------
    //input  logic        rob_full,
    //input  logic        int_rs_full,
    //input  logic        ls_rs_full,
    //input  logic        branch_rs_full,

    //----------------------------------
    // ROB allocation input
    //----------------------------------
   // input  logic [4:0]  rob_alloc_idx,

    //----------------------------------
    // Stall backpressure
    //----------------------------------
    //output logic        stall,

    //----------------------------------
    // ROB interface
    //----------------------------------
    output logic        rob_we,
    output logic [4:0]  rob_rd,
    output logic [5:0] rob_prd,

    //----------------------------------
    // Integer enable + source/dest physical registers
    //----------------------------------
    output logic        int_rs_we,
    output logic [5:0]  rs_prs1,
    output logic [5:0]  rs_prs2,
    output logic [5:0]  rs_prd,

    //----------------------------------
    // Load/Store RS (minimal)
    //----------------------------------
    output logic        ls_rs_we,

    //----------------------------------
    // Branch RS (minimal)
    //----------------------------------
    output logic        branch_rs_we,
    output logic [6:0]  branch_tag_out,
    output logic [4:0] micro_op_out,
    output logic needs_pc
);

logic        next_rob_we;
logic [4:0]  next_rob_rd;
logic [5:0]  next_rob_prd;

logic        next_int_rs_we;
logic [5:0]  next_rs_prs1;
logic [5:0]  next_rs_prs2;
logic [5:0]  next_rs_prd;
logic [6:0]  next_branch_tag_out;

logic        next_ls_rs_we;
logic        next_branch_rs_we;
logic [4:0]  micro_op; // micro-op code for the instruction
logic next_needs_pc; // indicates if the instruction needs the PC (for branches/jumps)  
 // -----------------------------
    // Opcode extraction
    // -----------------------------

    //logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_bit;


    //assign opcode     = instruction[6:0];
    assign funct3     = instruction[14:12];
    assign funct7_bit = instruction[30];


    // -----------------------------
    // Micro-op encoding
    // -----------------------------

    localparam logic [4:0]

    OP_ADD   = 5'd0,
    OP_SUB   = 5'd1,
    OP_AND   = 5'd2,
    OP_OR    = 5'd3,
    OP_XOR   = 5'd4,
    OP_SLL   = 5'd5,
    OP_SRL   = 5'd6,
    OP_SRA   = 5'd7,
    OP_SLT   = 5'd8,
    OP_SLTU  = 5'd9,

    OP_LUI   = 5'd10,
    OP_AUIPC = 5'd11,

    OP_BEQ   = 5'd12,
    OP_BNE   = 5'd13,
    OP_BLT   = 5'd14,
    OP_BGE   = 5'd15,
    OP_BLTU  = 5'd16,
    OP_BGEU  = 5'd17,

    OP_LB    = 5'd18,
    OP_LH    = 5'd19,
    OP_LW    = 5'd20,
    OP_LBU   = 5'd21,
    OP_LHU   = 5'd22,

    OP_SB    = 5'd23,
    OP_SH    = 5'd24,
    OP_SW    = 5'd25,

    OP_JAL   = 5'd26,
    OP_JALR  = 5'd27;


always_ff @(posedge clk) begin

    //----------------------------------
    // Reset: clear all outputs
    //----------------------------------
    if (reset) begin

        rob_we        <= 1'b0;
        rob_rd        <= '0;
        rob_prd       <= '0;

        int_rs_we     <= 1'b0;
        rs_prs1       <= '0;
        rs_prs2       <= '0;
        rs_prd        <= '0;

        ls_rs_we      <= 1'b0;
        branch_rs_we  <= 1'b0;
        branch_tag_out <= '0;
        micro_op_out <= '0;
        needs_pc <= 1'b0;

    end

    //----------------------------------
    // Normal operation: register next state
    //----------------------------------
    else begin
        
        if(valid)begin
            rob_we        <= next_rob_we;
            int_rs_we     <= next_int_rs_we;
            branch_rs_we      <= next_branch_rs_we;
        end
        else begin
            rob_we <= 0;
            int_rs_we <= 0;
            branch_rs_we <= 0;

        end
        rob_rd        <= next_rob_rd;
        rob_prd       <= next_rob_prd;

        rs_prs1       <= next_rs_prs1;
        rs_prs2       <= next_rs_prs2;
        rs_prd        <= next_rs_prd; // <-- fix below note

        ls_rs_we      <= next_ls_rs_we;
       
        branch_tag_out <= next_branch_tag_out;
        micro_op_out <= micro_op;
        needs_pc <= next_needs_pc;

    end

end

always_comb begin 
    
    // -----------------------------
    // SAFE DEFAULTS
    // -----------------------------
    next_rob_we        = 1'b0;
    next_rob_rd        = '0;
    next_rob_prd       = '0;

    next_int_rs_we     = 1'b0;
    next_rs_prs1       = '0;
    next_rs_prs2       = '0;
    next_rs_prd        = '0;

    next_ls_rs_we      = 1'b0;
    next_branch_rs_we  = 1'b0;
    next_branch_tag_out = '0;
    next_needs_pc      = 1'b0;

    case (opcode)

        //----------------------------------
        // OP-IMM (Register-Immediate ALU ops)
        // addi, slti, sltiu, xori, ori, andi
        // slli, srli, srai
        //----------------------------------
        7'b0010011: begin
            next_rob_prd = prd;
            next_rob_we = 1'b1;
            next_rob_rd = arch_rd;

            next_int_rs_we = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prd = prd;
            
        end

        //----------------------------------
        // OP (Register-Register ALU ops)
        // add, sub, sll, slt, sltu, xor, srl, sra, or, and
        //----------------------------------
        7'b0110011: begin
            next_rob_prd = prd;
            next_rob_we = 1'b1;
            next_rob_rd = arch_rd;

            next_int_rs_we = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prs2 = prs2;
            next_rs_prd = prd;
            // OP
        end

        //----------------------------------
        // LOAD
        // lb, lh, lw, lbu, lhu
        //----------------------------------
        7'b0000011: begin
            next_rob_prd = prd;
            next_rob_we = 1'b1;
            next_rob_rd = arch_rd;

            next_ls_rs_we = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prd = prd;
            // LOAD
        end

        //----------------------------------
        // STORE
        // sb, sh, sw
        //----------------------------------
        7'b0100011: begin
            next_rob_prd = prd;
            next_rob_we = 1'b1;
            next_rob_rd = arch_rd;

            next_ls_rs_we = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prs2 = prs2;
            //next_rs_prd = prd;
            // STORE
        end

        //----------------------------------
        // BRANCH
        // beq, bne, blt, bge, bltu, bgeu
        //----------------------------------
        7'b1100011: begin
            // BRANCH
            next_branch_rs_we = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prs2 = prs2;
            next_branch_tag_out = branch_tag_in; // Pass the branch tag from RAT to Issue
            next_rob_we = 1'b1; // Allocate a ROB entry for the branch (for commit-time resolution)
            //next_rob_rd = arch_rd; // Not actually used for branches, but we can set it to the architectural rd for bookkeeping
            next_rob_prd = prd; // Use the branch tag as the destination register for the ROB entry
            next_needs_pc = 1'b1;

        end

        //----------------------------------
        // JAL
        // jump and link
        //----------------------------------
        7'b1101111: begin
            // JAL
            //Expected to be handled before reaching this stage, but we can still set up the outputs for completeness
            next_needs_pc = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prd = prd;
            next_rob_prd = prd;
        end

        //----------------------------------
        // JALR
        // jump and link register
        //----------------------------------
        7'b1100111: begin
            // JALR
            //Expected to be handled before reaching this stage, but we can still set up the outputs for completeness
            next_needs_pc = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prd = prd;
            next_rob_prd = prd;
        end

        //----------------------------------
        // LUI
        // load upper immediate
        //----------------------------------
        7'b0110111: begin
            // LUI
            next_ls_rs_we = 1'b1;
            next_rs_prd = prd;

            next_rob_prd = prd;
            next_rob_we = 1'b1;
            next_rob_rd = arch_rd;

        end

        //----------------------------------
        // AUIPC
        // add upper immediate to PC
        //----------------------------------
        7'b0010111: begin
            // AUIPC
            next_rob_prd = prd;
            next_rob_we = 1'b1;
            next_rob_rd = arch_rd;

            next_int_rs_we = 1'b1;
            next_rs_prs1 = prs1;
            next_rs_prd = prd;
            next_needs_pc = 1'b1;
        end

        //----------------------------------
        // SYSTEM
        // ecall, ebreak, CSR instructions
        //----------------------------------
        7'b1110011: begin
            // SYSTEM / CSR
            //not handling these in this simple implementation, but we could set up the outputs if we wanted to
        end

        //----------------------------------
        // DEFAULT (illegal / NOP handling)
        //----------------------------------
        default: begin
            // illegal opcode / NOP
        end

    endcase
end

// -----------------------------
    // Decoder
    // -----------------------------

    always_comb begin

        micro_op = OP_ADD; // safe default


        case(opcode)


            // -------------------------
            // R-Type
            // -------------------------
            7'b0110011: begin

                case(funct3)

                    3'b000:
                        micro_op = funct7_bit ? OP_SUB : OP_ADD;

                    3'b111:
                        micro_op = OP_AND;

                    3'b110:
                        micro_op = OP_OR;

                    3'b100:
                        micro_op = OP_XOR;

                    3'b001:
                        micro_op = OP_SLL;

                    3'b101:
                        micro_op = funct7_bit ? OP_SRA : OP_SRL;

                    3'b010:
                        micro_op = OP_SLT;

                    3'b011:
                        micro_op = OP_SLTU;


                    default:
                        micro_op = OP_ADD;

                endcase

            end



            // -------------------------
            // I-Type ALU
            // -------------------------
            // -------------------------

            7'b0010011: begin

                case(funct3)

                    // ADDI
                    3'b000:
                        micro_op = OP_ADD;

                    // SLTI
                    3'b010:
                        micro_op = OP_SLT;

                    // SLTIU
                    3'b011:
                        micro_op = OP_SLTU;

                    // XORI
                    3'b100:
                        micro_op = OP_XOR;

                    // SLLI
                    3'b001:
                        micro_op = OP_SLL;

                    // SRLI / SRAI
                    3'b101:
                        micro_op = funct7_bit ? OP_SRA : OP_SRL;

                    // ORI
                    3'b110:
                        micro_op = OP_OR;

                    // ANDI
                    3'b111:
                        micro_op = OP_AND;

                    default:
                        micro_op = OP_ADD;

                endcase

            end



            // -------------------------
            // LOAD (I-Type)
            // -------------------------
            7'b0000011: begin

                case(funct3)

                    3'b000:
                        micro_op = OP_LB;     // LB

                    3'b001:
                        micro_op = OP_LH;     // LH

                    3'b010:
                        micro_op = OP_LW;     // LW

                    3'b100:
                        micro_op = OP_LBU;    // LBU

                    3'b101:
                        micro_op = OP_LHU;    // LHU

                    default:
                        micro_op = OP_LW;     // safe default

                endcase

            end

            // -------------------------
            // STORE (S-Type)
            // -------------------------
            7'b0100011: begin

                case(funct3)

                    3'b000:
                        micro_op = OP_SB;     // SB

                    3'b001:
                        micro_op = OP_SH;     // SH

                    3'b010:
                        micro_op = OP_SW;     // SW

                    default:
                        micro_op = OP_SW;     // safe default

                endcase
            end



            // -------------------------
            // BRANCH
            // -------------------------
            7'b1100011: begin

                case(funct3)

                    3'b000:
                        micro_op = OP_BEQ;

                    3'b001:
                        micro_op = OP_BNE;

                    3'b100:
                        micro_op = OP_BLT;

                    3'b101:
                        micro_op = OP_BGE;

                    default:
                        micro_op = OP_BEQ;

                endcase

            end



            // -------------------------
            // Jumps
            // -------------------------
            7'b1101111:
                micro_op = OP_JAL;


            7'b1100111:
                micro_op = OP_JALR;



            // -------------------------
            // U-Type
            // -------------------------
            7'b0110111:
                micro_op = OP_LUI;


            7'b0010111:
                micro_op = OP_AUIPC;



            default:
                micro_op = OP_ADD;


        endcase

    end

endmodule