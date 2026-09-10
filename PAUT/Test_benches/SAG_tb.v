//======================================================================
// SAG_tb.v
// Simple testbench for Steering Angle Generator
//======================================================================

`timescale 1ns/1ps

module SAG_tb;

    reg clk;
    reg rst_n;
    reg angle_valid;
    reg [7:0] theta_idx;

    wire sin_valid;
    wire [31:0] sin_theta;


    // --------------------------------------------------------------
    // DUT
    // --------------------------------------------------------------

    SAG dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .angle_valid (angle_valid),
        .theta_idx   (theta_idx),
        .sin_valid   (sin_valid),
        .sin_theta   (sin_theta)
    );


    // --------------------------------------------------------------
    // Clock
    // --------------------------------------------------------------

    initial clk = 0;

    always #5 clk = ~clk;


    // --------------------------------------------------------------
    // Test
    // --------------------------------------------------------------

    initial begin

        rst_n       = 0;
        angle_valid = 0;
        theta_idx   = 0;

        // Reset
        #20;

        rst_n = 1;


        // ----------------------------------------------------------
        // -70°
        // theta_idx = 0
        // ----------------------------------------------------------

        @(negedge clk);

        theta_idx   = 0;
        angle_valid = 1;

        @(negedge clk);

        angle_valid = 0;

        $display(
            "-70 deg : sin = 0x%08h, valid = %b",
            sin_theta,
            sin_valid
        );


        // ----------------------------------------------------------
        // -60°
        // theta_idx = 10
        // ----------------------------------------------------------

        @(negedge clk);

        theta_idx   = 10;
        angle_valid = 1;

        @(negedge clk);

        angle_valid = 0;

        $display(
            "-60 deg : sin = 0x%08h, valid = %b",
            sin_theta,
            sin_valid
        );


        // ----------------------------------------------------------
        // -30°
        // theta_idx = 40
        // ----------------------------------------------------------

        @(negedge clk);

        theta_idx   = 40;
        angle_valid = 1;

        @(negedge clk);

        angle_valid = 0;

        $display(
            "-30 deg : sin = 0x%08h, valid = %b",
            sin_theta,
            sin_valid
        );


        // ----------------------------------------------------------
        // 0°
        // theta_idx = 70
        // ----------------------------------------------------------

        @(negedge clk);

        theta_idx   = 70;
        angle_valid = 1;

        @(negedge clk);

        angle_valid = 0;

        $display(
            "  0 deg : sin = 0x%08h, valid = %b",
            sin_theta,
            sin_valid
        );


        // ----------------------------------------------------------
        // +30°
        // theta_idx = 100
        // ----------------------------------------------------------

        @(negedge clk);

        theta_idx   = 100;
        angle_valid = 1;

        @(negedge clk);

        angle_valid = 0;

        $display(
            "+30 deg : sin = 0x%08h, valid = %b",
            sin_theta,
            sin_valid
        );


        // ----------------------------------------------------------
        // +60°
        // theta_idx = 130
        // ----------------------------------------------------------

        @(negedge clk);

        theta_idx   = 130;
        angle_valid = 1;

        @(negedge clk);

        angle_valid = 0;

        $display(
            "+60 deg : sin = 0x%08h, valid = %b",
            sin_theta,
            sin_valid
        );


        // ----------------------------------------------------------
        // +70°
        // theta_idx = 140
        // ----------------------------------------------------------

        @(negedge clk);

        theta_idx   = 140;
        angle_valid = 1;

        @(negedge clk);

        angle_valid = 0;

        $display(
            "+70 deg : sin = 0x%08h, valid = %b",
            sin_theta,
            sin_valid
        );


        #20;

        $finish;

    end

endmodule