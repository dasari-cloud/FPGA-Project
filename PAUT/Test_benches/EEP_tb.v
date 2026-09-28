`timescale 1ns/1ps

module EEP_tb;

    reg clk;
    reg rst_n;
    reg elem_valid;
    reg [4:0] elem_idx;

    wire pos_valid;
    wire [31:0] elem_x;
    wire [31:0] elem_z;

    // DUT
    EEP #(
        .N(32),
        .PITCH_MM(0.6)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .elem_valid (elem_valid),
        .elem_idx   (elem_idx),
        .pos_valid  (pos_valid),
        .elem_x     (elem_x),
        .elem_z     (elem_z)
    );

    // Clock: 10 ns period = 100 MHz
    always #5 clk = ~clk;

    initial begin

        clk        = 0;
        rst_n      = 0;
        elem_valid = 0;
        elem_idx   = 0;

        // Reset
        #20;
        rst_n = 1;

        // ------------------------------------------------
        // Element 0
        // X = (0 - 15.5)*0.6 = -9.3 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 0;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E0  : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);


        // ------------------------------------------------
        // Element 8
        // X = (8 - 15.5)*0.6 = -4.5 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 8;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E8  : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);


        // ------------------------------------------------
        // Element 15
        // X = (15 - 15.5)*0.6 = -0.3 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 15;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E15 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);


        // ------------------------------------------------
        // Element 16
        // X = (16 - 15.5)*0.6 = +0.3 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 16;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E16 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);


        // ------------------------------------------------
        // Element 23
        // X = (23 - 15.5)*0.6 = +4.5 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 23;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E23 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);


        // ------------------------------------------------
        // Element 31
        // X = (31 - 15.5)*0.6 = +9.3 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 31;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E31 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);

        #20;

        $finish;
    end

endmodule