
// SAG_tb.v - Testbench for Steering Angle Generator
//
// Verifies:
//   theta_idx = 0 -> 40 degrees
//   theta_idx = 1 -> 55 degrees
//   theta_idx = 2 -> 70 degrees
//
// Checks:
//   1. sin(theta)
//   2. cos(theta)
//   3. trig_valid
//   4. Back-to-back pipelined operation
//
// Clock:
//   100 MHz
//======================================================================

`timescale 1ns/1ps

module SAG_tb;

    reg         clk;
    reg         rst_n;
    reg         angle_valid;
    reg  [1:0]  theta_idx;

    wire        trig_valid;
    wire [31:0] sin_theta;
    wire [31:0] cos_theta;


    //==================================================================
    // Expected IEEE-754 FLOAT32 values
    //==================================================================

    localparam [31:0] SIN_40 = 32'h3F248DBB;
    localparam [31:0] COS_40 = 32'h3F441B7D;

    localparam [31:0] SIN_55 = 32'h3F51B3F3;
    localparam [31:0] COS_55 = 32'h3F12D0E5;

    localparam [31:0] SIN_70 = 32'h3F708FB2;
    localparam [31:0] COS_70 = 32'h3EAF1D44;


    //==================================================================
    // DUT
    //==================================================================

    SAG dut (
        .clk         (clk),
        .rst_n       (rst_n),

        .angle_valid (angle_valid),
        .theta_idx   (theta_idx),

        .trig_valid  (trig_valid),
        .sin_theta   (sin_theta),
        .cos_theta   (cos_theta)
    );


    //==================================================================
    // Clock
    // 10 ns period = 100 MHz
    //==================================================================

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;


    //==================================================================
    // Output checker
    //==================================================================

    task check_output;

    input [1:0]  expected_idx;
    input [31:0] expected_sin;
    input [31:0] expected_cos;

    begin

        if (!trig_valid) begin

            $display(
                "FAIL : theta_idx=%0d : trig_valid = 0",
                expected_idx
            );

        end

        else if ((sin_theta != expected_sin) ||
                 (cos_theta != expected_cos)) begin

            $display(
                "FAIL : theta_idx=%0d : sin=0x%08h cos=0x%08h",
                expected_idx,
                sin_theta,
                cos_theta
            );

        end

        else begin

            $display(
                "PASS : theta_idx=%0d : sin=0x%08h cos=0x%08h",
                expected_idx,
                sin_theta,
                cos_theta
            );

        end

    end

endtask
    //==================================================================
    // Test
    //==================================================================

    initial begin

        rst_n       = 1'b0;
        angle_valid = 1'b0;
        theta_idx   = 2'd0;


        //==============================================================
        // Reset
        //==============================================================

        repeat (2) @(negedge clk);

        rst_n = 1'b1;


        //==============================================================
        // Test 40 degrees
        //==============================================================

        @(negedge clk);

        theta_idx   = 2'd0;
        angle_valid = 1'b1;

        @(negedge clk);

        angle_valid = 1'b0;

        check_output(
            2'd0,
            SIN_40,
            COS_40
        );


        //==============================================================
        // Test 55 degrees
        //==============================================================

        @(negedge clk);

        theta_idx   = 2'd1;
        angle_valid = 1'b1;

        @(negedge clk);

        angle_valid = 1'b0;

        check_output(
            2'd1,
            SIN_55,
            COS_55
        );


        //==============================================================
        // Test 70 degrees
        //==============================================================

        @(negedge clk);

        theta_idx   = 2'd2;
        angle_valid = 1'b1;

        @(negedge clk);

        angle_valid = 1'b0;

        check_output(
            2'd2,
            SIN_70,
            COS_70
        );


        //==============================================================
        // Pipeline test
        //
        // Send:
        //     40 -> 55 -> 70
        //
        // without gaps.
        //==============================================================

        $display("");
        $display("==============================================");
        $display("Back-to-back pipeline test");
        $display("==============================================");


        @(negedge clk);

        angle_valid = 1'b1;
        theta_idx   = 2'd0;          // 40 deg


        @(negedge clk);

        // 40-degree result should now be available

        if (trig_valid &&
            sin_theta == SIN_40 &&
            cos_theta == COS_40)

            $display("PIPE PASS : 40 deg");

        else

            $display("PIPE FAIL : 40 deg");


        theta_idx = 2'd1;            // 55 deg


        @(negedge clk);

        // 55-degree result

        if (trig_valid &&
            sin_theta == SIN_55 &&
            cos_theta == COS_55)

            $display("PIPE PASS : 55 deg");

        else

            $display("PIPE FAIL : 55 deg");


        theta_idx = 2'd2;            // 70 deg


        @(negedge clk);

        // 70-degree result

        if (trig_valid &&
            sin_theta == SIN_70 &&
            cos_theta == COS_70)

            $display("PIPE PASS : 70 deg");

        else

            $display("PIPE FAIL : 70 deg");


        // Stop input
        angle_valid = 1'b0;


        //==============================================================
        // Finish
        //==============================================================

        repeat (2) @(negedge clk);

        $display("");
        $display("SAG simulation completed.");

        $finish;

    end

endmodule