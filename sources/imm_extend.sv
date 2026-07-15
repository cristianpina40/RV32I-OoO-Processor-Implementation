`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 11:40:18 PM
// Design Name: 
// Module Name: imm_extend
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


module imm_extend (

    input logic clk,
    input logic reset,

    //----------------------------------
    // Decode inputs
    //----------------------------------
    input logic [31:0] instruction,
    input logic        imm_needed,

    //----------------------------------
    // Output to Rename / Dispatch
    //----------------------------------
    output logic [31:0] imm

);


logic [31:0] next_imm;


always_comb begin

    next_imm = 32'b0;

    //if (imm_needed) begin

        case(instruction[6:0])

            //----------------------------------
            // I-Type
            // OP-IMM, LOAD, JALR
            //----------------------------------
            7'b0010011,
            7'b0000011,
            7'b1100111: begin

                next_imm = {{20{instruction[31]}},
                            instruction[31:20]};

            end


            //----------------------------------
            // S-Type
            // STORE
            //----------------------------------
            7'b0100011: begin

                next_imm = {{20{instruction[31]}},
                            instruction[31:25],
                            instruction[11:7]};

            end


            //----------------------------------
            // B-Type
            // BRANCH
            //----------------------------------
            7'b1100011: begin

                next_imm = {{19{instruction[31]}},
                            instruction[31],
                            instruction[7],
                            instruction[30:25],
                            instruction[11:8],
                            1'b0};

            end


            //----------------------------------
            // U-Type
            // LUI / AUIPC
            //----------------------------------
            7'b0110111,
            7'b0010111: begin

                next_imm = {instruction[31:12],12'b0};

            end


            //----------------------------------
            // J-Type
            // JAL
            //----------------------------------
            7'b1101111: begin

                next_imm = {{11{instruction[31]}},
                            instruction[31],
                            instruction[19:12],
                            instruction[20],
                            instruction[30:21],
                            1'b0};

            end


            default: begin

                next_imm = 32'b0;

            end

        endcase

    //end

end



//----------------------------------
// Immediate pipeline register
//----------------------------------

always_ff @(posedge clk) begin

    if(reset) begin

        imm <= 32'b0;

    end

    else begin

        imm <= next_imm;

    end

end


endmodule