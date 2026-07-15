`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2026 11:27:21 AM
// Design Name: 
// Module Name: inst_mem
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


module inst_memory #(
    parameter DEPTH = 100, parameter ADDR_W = 32
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [ADDR_W-1:0] pc,
    input logic valid,
    output logic [ADDR_W-1:0] instruction
);

    //--------------------------------------------------
    // Instruction Memory
    // Each location stores one 32-bit instruction
    //--------------------------------------------------

    logic [ADDR_W-1:0] inst_mem [0:DEPTH-1];

    //--------------------------------------------------
    // Optional program initialization
    //--------------------------------------------------

    initial begin
        //$readmemh("program.hex", inst_mem);
        /********
        inst_mem[0]  = 32'h00000093; // 0x00  addi x1,  x0, 0        ; x1 = 0
        inst_mem[1]  = 32'h00500113; // 0x04  addi x2,  x0, 5        ; x2 = 5
        inst_mem[2]  = 32'h00A00193; // 0x08  addi x3,  x0, 10       ; x3 = 10
        inst_mem[3]  = 32'h00208233; // 0x0C  add  x4,  x1, x2       ; x4 = 5
        inst_mem[4]  = 32'h003202B3; // 0x10  add  x5,  x4, x3       ; x5 = 15
        inst_mem[5]  = 32'h40228333; // 0x14  sub  x6,  x5, x2       ; x6 = 10
        inst_mem[6]  = 32'h006303B3; // 0x18  add  x7,  x6, x6       ; x7 = 20
        inst_mem[7]  = 32'h00738433; // 0x1C  add  x8,  x7, x7       ; x8 = 40

        inst_mem[8]  = 32'h00808463; // 0x20  beq  x1, x8, +8       ; NOT taken
        inst_mem[9]  = 32'h00900463; // 0x24  beq  x0, x9, +8       ; taken
        inst_mem[10] = 32'h00100193; // 0x28  addi x3,  x0, 1       ; skipped
        inst_mem[11] = 32'h00200213; // 0x2C  addi x4,  x0, 2       ; skipped

        inst_mem[12] = 32'h00A00513; // 0x30  addi x10, x0, 10      ; target
        inst_mem[13] = 32'h00B00593; // 0x34  addi x11, x0, 11
        inst_mem[14] = 32'h00C00613; // 0x38  addi x12, x0, 12
        inst_mem[15] = 32'h00D00693; // 0x3C  addi x13, x0, 13

        inst_mem[16] = 32'h00B606B3; // 0x40  add x13, x12, x11
        inst_mem[17] = 32'h00D68733; // 0x44  add x14, x13, x13
        inst_mem[18] = 32'h00E707B3; // 0x48  add x15, x14, x14

        inst_mem[19] = 32'h000004EF; // 0x4C  jal x9, +0           ; link test

        inst_mem[20] = 32'h01000893; // 0x50  addi x17, x0, 16
        inst_mem[21] = 32'h01100913; // 0x54  addi x18, x0, 17
        inst_mem[22] = 32'h01200993; // 0x58  addi x19, x0, 18
        inst_mem[23] = 32'h01300A13; // 0x5C  addi x20, x0, 19

        inst_mem[24] = 32'h013A0AB3; // 0x60  add x21, x20, x19
        inst_mem[25] = 32'h015A8B33; // 0x64  add x22, x21, x21
        inst_mem[26] = 32'h016B0BB3; // 0x68  add x23, x22, x22
        inst_mem[27] = 32'h017B8C33; // 0x6C  add x24, x23, x23

        inst_mem[28] = 32'h018C0CB3; // 0x70  add x25, x24, x24
        inst_mem[29] = 32'h019C8D33; // 0x74  add x26, x25, x25
        inst_mem[30] = 32'h01AD0DB3; // 0x78  add x27, x26, x26
        inst_mem[31] = 32'h01BD8E33; // 0x7C  add x28, x27, x27

        inst_mem[32] = 32'h01CE0EB3; // 0x80  add x29, x28, x28
        inst_mem[33] = 32'h01DE8F33; // 0x84  add x30, x29, x29
        inst_mem[34] = 32'h01E80FB3; // 0x88  add x31, x16, x30

        inst_mem[35] = 32'h00108093; // 0x8C  addi x1, x1, 1
        inst_mem[36] = 32'h00208093; // 0x90  addi x1, x1, 2
        inst_mem[37] = 32'h00308093; // 0x94  addi x1, x1, 3
        inst_mem[38] = 32'h00408093; // 0x98  addi x1, x1, 4

        inst_mem[39] = 32'h00508113; // 0x9C  addi x2, x1, 5
        inst_mem[40] = 32'h00610193; // 0xA0  addi x3, x2, 6
        inst_mem[41] = 32'h00718213; // 0xA4  addi x4, x3, 7
        inst_mem[42] = 32'h00820293; // 0xA8  addi x5, x4, 8

        inst_mem[43] = 32'h00928313; // 0xAC  addi x6, x5, 9
        inst_mem[44] = 32'h00A30393; // 0xB0  addi x7, x6, 10
        inst_mem[45] = 32'h00B38413; // 0xB4  addi x8, x7, 11
        inst_mem[46] = 32'h00C40493; // 0xB8  addi x9, x8, 12

        inst_mem[47] = 32'h00150513; // 0xBC  addi x10, x10, 1
        inst_mem[48] = 32'h00258593; // 0xC0  addi x11, x11, 2
        inst_mem[49] = 32'h00360613; // 0xC4  addi x12, x12, 3
        ***************/

        inst_mem[1]  = 32'b00000000101000000000000010010011; // addi x1, x0, 10        (x1 = 10)
        inst_mem[2]  = 32'b00000001010000000000000100010011; // addi x2, x0, 20        (x2 = 20)
        inst_mem[3]  = 32'b11111111101100000000000110010011; // addi x3, x0, -5        (x3 = -5)
        inst_mem[4]  = 32'b00000000001000001000001000110011; // add  x4, x1, x2        (x4 = 30)
        inst_mem[5]  = 32'b01000000000100010000001010110011; // sub  x5, x2, x1        (x5 = 10)
        inst_mem[6]  = 32'b00000000001000001111001100110011; // and  x6, x1, x2
        inst_mem[7]  = 32'b00000000001000001110001110110011; // or   x7, x1, x2
        inst_mem[8]  = 32'b00000000001000001100010000110011; // xor  x8, x1, x2
        inst_mem[9]  = 32'b00000000000000001111010010010011; // andi x9,  x1, 0x0F
        inst_mem[10]  = 32'b00000000000000001110010100010011; // ori  x10, x1, 0x0F
        inst_mem[11] = 32'b00000000000000001100010110010011; // xori x11, x1, 0x0F
        inst_mem[12] = 32'b00000000001000001001011000010011; // slli x12, x1, 2
        inst_mem[13] = 32'b00000000000100001101011010010011; // srli x13, x1, 1
        inst_mem[14] = 32'b01000000000100011101011100010011; // srai x14, x3, 1
        inst_mem[15] = 32'b00000000001000001001011110110011; // sll  x15, x1, x2
        inst_mem[16] = 32'b00000000001000001101100000110011; // srl  x16, x1, x2
        inst_mem[17] = 32'b01000000000100011101100010110011; // sra  x17, x3, x1
        inst_mem[18] = 32'b00000000000100011010100100110011; // slt  x18, x3, x1       (-> 1)
        inst_mem[19] = 32'b00000000000100011011100110110011; // sltu x19, x3, x1       (-> 0)
        inst_mem[20] = 32'b00000110010000001010101000010011; // slti  x20, x1, 100     (-> 1)
        inst_mem[21] = 32'b00000110010000001011101010010011; // sltiu x21, x1, 100     (-> 1)
        inst_mem[22] = 32'b00000000000100000000101100010011; // addi x22, x0, 1
        inst_mem[23] = 32'b00000001011010110000101110110011; // add  x23, x22, x22
        inst_mem[24] = 32'b00000001011010111000110000110011; // add  x24, x23, x22     (RAW on x23)
        inst_mem[25] = 32'b00000001011111000000110010110011; // add  x25, x24, x23     (RAW on x24 & x23)
        //inst_mem[49] = 32'h00ED8D93; // addi x27, x27, 14
    end

    //--------------------------------------------------
    // Synchronous Instruction Fetch
    //--------------------------------------------------

    always_ff @(posedge clk) begin
        if(reset)begin 
            instruction <= '0;
        end
        else begin 
            if(valid)begin
                instruction <= inst_mem[pc[31:2]];
            end
            else begin
                instruction <= '0;
            end
    end
end


endmodule
