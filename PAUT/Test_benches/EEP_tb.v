`timescale 1ns/1ps

module EEP_tb;

    reg clk;
    reg rst_n;
    reg elem_valid;
    reg [5:0] elem_idx;

    wire pos_valid;
    wire [31:0] elem_x;
    wire [31:0] elem_z;

    // DUT
    EEP dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .elem_valid (elem_valid),
        .elem_idx   (elem_idx),
        .pos_valid  (pos_valid),
        .elem_x     (elem_x),
        .elem_z     (elem_z)
    );

    // Clock: 10 ns
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
        // Expected X = -15.75 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 0;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E0  : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);

        // ------------------------------------------------
        // Element 16
        // Expected X = -7.75 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 16;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E16 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);

        // ------------------------------------------------
        // Element 31
        // Expected X = -0.25 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 31;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E31 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);

        // ------------------------------------------------
        // Element 32
        // Expected X = +0.25 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 32;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E32 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);

        // ------------------------------------------------
        // Element 47
        // Expected X = +7.75 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 47;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E47 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);

        // ------------------------------------------------
        // Element 63
        // Expected X = +15.75 mm
        // ------------------------------------------------
        @(negedge clk);
        elem_idx   = 63;
        elem_valid = 1;

        @(negedge clk);
        elem_valid = 0;

        $display("E63 : X = 0x%08h, Z = 0x%08h, valid = %b",
                 elem_x, elem_z, pos_valid);

        #20;

        $finish;
    end

endmodule