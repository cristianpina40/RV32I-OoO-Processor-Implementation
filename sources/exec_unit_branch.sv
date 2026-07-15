`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2026 03:25:19 PM
// Design Name: 
// Module Name: exec_unit_branch
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


module exec_unit_branch #(
    parameter REG_W = 6
)(
    input  logic clk,
    input  logic reset,

    //----------------------------------
    // From RS
    //----------------------------------
    input  logic        valid_in,

    input  logic [4:0]  micro_op,

    input  logic [REG_W-1:0] prs1,
    input  logic [REG_W-1:0] prs2,
    input  logic [REG_W-1:0] prd,

    input  logic [31:0] op_a,   // rs1 value
    input  logic [31:0] op_b,   // rs2 value (not used for JALR)
    input  logic [31:0] imm,
    input  logic [31:0] pc,

    //----------------------------------
    // Outputs
    //----------------------------------
    output logic        ready_out,
    output logic        cdb_valid,
    output logic [REG_W-1:0] cdb_prd,
    //output logic [31:0] cdb_result,

    output logic        redirect_valid,
    output logic [31:0] redirect_pc
    //output logic        taken

);

localparam logic [4:0]
    ADD     = 5'd0,
    SUB     = 5'd1,

    AND     = 5'd2,
    OR      = 5'd3,
    XOR     = 5'd4,

    SLL     = 5'd5,
    SRL     = 5'd6,
    SRA     = 5'd7,

    SLT     = 5'd8,
    SLTU    = 5'd9,

// -------------------------
// U-type
// -------------------------
    LUI     = 5'd10,
    AUIPC   = 5'd11,

// -------------------------
// Branch ops
// -------------------------
    BEQ     = 5'd12,
    BNE     = 5'd13,
    BLT     = 5'd14,
    BGE     = 5'd15,
    BLTU    = 5'd16,
    BGEU    = 5'd17,

// -------------------------
// LOAD ops (LSU)
// -------------------------
    LB      = 5'd18,
    LH      = 5'd19,
    LW      = 5'd20,
    LBU     = 5'd21,
    LHU     = 5'd22,

// -------------------------
// STORE ops (LSU)
// -------------------------
    SB      = 5'd23,
    SH      = 5'd24,
    SW      = 5'd25,

// -------------------------
// Special
// -------------------------
    PASS_A  = 5'd26,
    PASS_B  = 5'd27,

    JALR    = 5'd28;
    
    logic cond;
    logic [31:0] target_pc;

    always_comb begin

        cond = 1'b0;
        target_pc = 32'b0;
        //taken = 1'b0;

        if (valid_in) begin

            case (micro_op)

                // -------------------------
                // Conditional branches
                // -------------------------
                BEQ:  cond = (op_a == op_b);
                BNE:  cond = (op_a != op_b);

                BLT:  cond = ($signed(op_a) < $signed(op_b));
                BGE:  cond = ($signed(op_a) >= $signed(op_b));

                BLTU: cond = (op_a < op_b);
                BGEU: cond = (op_a >= op_b);

                // -------------------------
                // JALR (INDIRECT JUMP)
                // -------------------------
                JALR: begin
                    cond = 1'b1; // always taken
                    target_pc = (op_a + imm) & ~32'b1; // clear LSB
                end

                default: cond = 1'b0;

            endcase

            // normal branches
            if (micro_op != JALR) begin
                target_pc = pc + imm;
            end

            //taken = cond;
        end
    end

    always_ff @(posedge clk) begin

        if (reset) begin
            cdb_valid     <= 0;
            cdb_prd       <= 0;
           // cdb_result    <= 0;

            redirect_valid <= 0;
            redirect_pc    <= 0;
            ready_out      <= 0;
            //taken          <= 0;
        end

        else begin

            cdb_valid <= valid_in;
            cdb_prd   <= prd;

            // encode branch outcome
           // cdb_result <= {31'b0, taken};

            // redirect logic
            redirect_valid <= valid_in && cond;
            redirect_pc    <= target_pc;

            ready_out <= 1;
        end
    end

endmodule