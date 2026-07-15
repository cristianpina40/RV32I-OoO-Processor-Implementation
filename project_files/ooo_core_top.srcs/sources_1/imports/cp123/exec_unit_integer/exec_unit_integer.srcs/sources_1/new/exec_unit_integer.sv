`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2026 02:55:31 PM
// Design Name: 
// Module Name: exec_unit_integer
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


module exec_unit_integer
 #(
    parameter REG_W = 6
)(
    input  logic clk,
    input  logic reset,

    //----------------------------------
    // From Reservation Station
    //----------------------------------
    input  logic        valid_in,

    input  logic [4:0]  micro_op,

    input  logic [REG_W-1:0] prs1,
    input  logic [REG_W-1:0] prs2,
    input  logic [REG_W-1:0] prd,

    input  logic [31:0]  op_a,      // value from PRF[prs1]
    input  logic [31:0]  op_b,      // value from PRF[prs2] OR imm
    input  logic [31:0]  imm,
    input  logic [31:0]  pc,

    input  logic        uses_imm,
    input  logic        uses_pc,

    //----------------------------------
    // Pipeline control
    //----------------------------------
    output logic        ready_out,

    //----------------------------------
    // To CDB (writeback)
    //----------------------------------
    output logic        cdb_valid,
    output logic [REG_W-1:0] cdb_prd,
    output logic [31:0] cdb_result

);

localparam logic [4:0]

    // -------------------------
    // Integer ALU operations
    // -------------------------
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
    // U-Type operations
    // -------------------------
    LUI     = 5'd10,
    AUIPC   = 5'd11,


    // -------------------------
    // Branch operations
    // -------------------------
    BEQ     = 5'd12,
    BNE     = 5'd13,
    BLT     = 5'd14,
    BGE     = 5'd15,
    BLTU    = 5'd16,
    BGEU    = 5'd17,


    // -------------------------
    // Load operations
    // -------------------------
    LB      = 5'd18,
    LH      = 5'd19,
    LW      = 5'd20,
    LBU     = 5'd21,
    LHU     = 5'd22,


    // -------------------------
    // Store operations
    // -------------------------
    SB      = 5'd23,
    SH      = 5'd24,
    SW      = 5'd25,


    // -------------------------
    // Jump operations
    // -------------------------
    JAL     = 5'd26,
    JALR    = 5'd27,


    // -------------------------
    // Special operations
    // -------------------------
    PASS_A  = 5'd28,
    PASS_B  = 5'd29;
    //----------------------------------
    // Internal result register
    //----------------------------------
    logic [31:0] result;

    //----------------------------------
    // ALU COMBINATIONAL LOGIC
    //----------------------------------
    always_comb begin

        // default
        result = 32'b0;

        if (valid_in) begin

            // Select operand B
            logic [31:0] b;
            b = (uses_imm) ? imm : op_b;

            case (micro_op)

                ADD:    result = op_a + b;
                SUB:    result = op_a - b;

                AND:    result = op_a & b;
                OR:     result = op_a | b;
                XOR:    result = op_a ^ b;

                SLL:    result = op_a << b[4:0];
                SRL:    result = op_a >> b[4:0];
                SRA:    result = $signed(op_a) >>> b[4:0];

                SLT:    result = ($signed(op_a) < $signed(b));
                SLTU:   result = (op_a < b);

                //----------------------------------
                // U-TYPE
                //----------------------------------
                LUI:    result = imm;
                AUIPC:  result = pc + imm;

                //----------------------------------
                // BRANCH COMPARE (optional use)
                //----------------------------------
                BEQ:    result = (op_a == b);
                BNE:    result = (op_a != b);
                BLT:    result = ($signed(op_a) < $signed(b));
                BGE:    result = ($signed(op_a) >= $signed(b));
                BLTU:   result = (op_a < b);
                BGEU:   result = (op_a >= b);

                //----------------------------------
                // PASS THROUGH
                //----------------------------------
                PASS_A: result = op_a;
                PASS_B: result = b;

                default: result = 32'b0;

            endcase
        end
    end

    //----------------------------------
    // OUTPUT REGISTER (1-cycle ALU)
    //----------------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            cdb_valid <= 0;
            cdb_prd   <= 0;
            cdb_result <= 0;
            ready_out  <= 0;
        end else begin
            cdb_valid <= valid_in;
            cdb_prd   <= prd;
            cdb_result <= result;
            ready_out  <= 1;
        end
    end

endmodule