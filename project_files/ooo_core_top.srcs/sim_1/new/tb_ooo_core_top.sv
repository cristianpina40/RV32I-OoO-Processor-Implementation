`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/12/2026 07:04:02 PM
// Design Name: 
// Module Name: tb_ooo_core_top
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


`timescale 1ns/1ps

module tb_ooo_core_top;

    //----------------------------------
    // Clock / Reset
    //----------------------------------
    logic clk;
    logic reset;

    //----------------------------------
    // Commit Outputs
    //----------------------------------
    logic commit_valid0_out;
    logic commit_valid1_out;

    logic [4:0] commit_rd0_out;
    logic [4:0] commit_rd1_out;

    logic [5:0] commit_prd0_output;
    logic [5:0] commit_prd1_output;


    //----------------------------------
    // Instantiate DUT
    //----------------------------------
    ooo_core_top dut (

        .clk(clk),
        .reset(reset),

        .commit_valid0_out(commit_valid0_out),
        .commit_valid1_out(commit_valid1_out),

        .commit_rd0_out(commit_rd0_out),
        .commit_rd1_out(commit_rd1_out),

        .commit_prd0_output(commit_prd0_output),
        .commit_prd1_output(commit_prd1_output)

    );


    //----------------------------------
    // Clock Generator
    //----------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100MHz clock
    end


    //----------------------------------
    // Reset Sequence
    //----------------------------------
    initial begin

        reset = 1;

        #20;

        reset = 0;

    end


    //----------------------------------
    // Monitor Commit Flow
    //----------------------------------
    always @(posedge clk) begin

        if(reset) begin
            $display("Cycle: RESET");
        end

        else begin

            $display(
                "Cycle %0t | Commit0=%b rd=%0d prd=%0d | Commit1=%b rd=%0d prd=%0d",
                $time,

                commit_valid0_out,
                commit_rd0_out,
                commit_prd0_output,

                commit_valid1_out,
                commit_rd1_out,
                commit_prd1_output
            );

        end

    end


    //----------------------------------
    // Run Simulation
    //----------------------------------
    initial begin

        #1000;

        $display("Simulation Finished");

        $finish;

    end


endmodule
