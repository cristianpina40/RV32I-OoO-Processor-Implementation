`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2026 02:11:48 PM
// Design Name: 
// Module Name: physical_regfile
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


module physical_regfile #(
    parameter DATA_WIDTH = 32,
    parameter PRF_DEPTH  = 64,
    parameter ADDR_W     = 6
)(
    
    input  logic                     clk,
    input  logic                     reset,
    // ----------------------------
    // 6 READ PORTS
    // ----------------------------
    input logic                     active_integer,
    input logic                     active_branch,
    input logic                     active_load_store,
    input  logic [ADDR_W-1:0]       raddr0,
    input  logic [ADDR_W-1:0]       raddr1,
    input  logic [ADDR_W-1:0]       raddr2,
    input  logic [ADDR_W-1:0]       raddr3,
    input  logic [ADDR_W-1:0]       raddr4,
    input  logic [ADDR_W-1:0]       raddr5,

    output logic [DATA_WIDTH-1:0]    rdata0,
    output logic [DATA_WIDTH-1:0]    rdata1,
    output logic [DATA_WIDTH-1:0]    rdata2,
    output logic [DATA_WIDTH-1:0]    rdata3,
    output logic [DATA_WIDTH-1:0]    rdata4,
    output logic [DATA_WIDTH-1:0]    rdata5,

    // ----------------------------
    // 2 WRITE PORTS (CDB)
    // ----------------------------
    input  logic                     we0,
    input  logic [ADDR_W-1:0]       waddr0,
    input  logic [DATA_WIDTH-1:0]   wdata0,

    input  logic                     we1,
    input  logic [ADDR_W-1:0]       waddr1,
    input  logic [DATA_WIDTH-1:0]   wdata1
);

    // ----------------------------
    // REGISTER ARRAY
    // ----------------------------
    logic [DATA_WIDTH-1:0] rf [PRF_DEPTH-1:0];

    integer i;

    // ----------------------------
    // WRITE LOGIC
    // ----------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < PRF_DEPTH; i++) begin
                rf[i] <= '0;
            end

            rdata0 <= '0;
            rdata1 <= '0;
            rdata2 <= '0;
            rdata3 <= '0;
            rdata4 <= '0;
            rdata5 <= '0;
        end else begin
            if (we0)
                rf[waddr0] <= wdata0;

            if (we1)
                rf[waddr1] <= wdata1;

            if (active_integer) begin
                rdata0 <= rf[raddr0];
                rdata1 <= rf[raddr1];
            end else begin
                rdata0 <= '0;
                rdata1 <= '0;
            end
            if (active_branch) begin
                rdata2 <= rf[raddr2];
                rdata3 <= rf[raddr3];
            end else begin
                rdata2 <= '0;
                rdata3 <= '0;
            end
            if (active_load_store) begin
                rdata4 <= rf[raddr4];
                rdata5 <= rf[raddr5];
            end else begin
                rdata4 <= '0;
                rdata5 <= '0;   
            end
        end
    end

   

endmodule
