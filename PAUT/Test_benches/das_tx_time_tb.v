`timescale 1ns / 1ps

module das_tx_time_tb;

    // ============================================================
    // Clock / reset
    // ============================================================

    reg clk;
    reg rst_n;

    reg        in_valid;
    reg [4:0]  aperture_idx;

    reg [31:0] x_pixel;
    reg [31:0] z_pixel;

    reg [31:0] tx_delay_0;
    reg [31:0] tx_delay_1;
    reg [31:0] tx_delay_2;
    reg [31:0] tx_delay_3;
    reg [31:0] tx_delay_4;
    reg [31:0] tx_delay_5;
    reg [31:0] tx_delay_6;
    reg [31:0] tx_delay_7;

    wire        tx_time_valid;
    wire [31:0] tx_time;


    // ============================================================
    // DUT
    // ============================================================

    das_tx_time dut (

        .clk            (clk),
        .rst_n          (rst_n),

        .in_valid       (in_valid),

        .aperture_idx   (aperture_idx),

        .x_pixel        (x_pixel),
        .z_pixel        (z_pixel),

        .tx_delay_0     (tx_delay_0),
        .tx_delay_1     (tx_delay_1),
        .tx_delay_2     (tx_delay_2),
        .tx_delay_3     (tx_delay_3),
        .tx_delay_4     (tx_delay_4),
        .tx_delay_5     (tx_delay_5),
        .tx_delay_6     (tx_delay_6),
        .tx_delay_7     (tx_delay_7),

        .tx_time_valid  (tx_time_valid),
        .tx_time        (tx_time)

    );


    // ============================================================
    // 100 MHz clock
    // ============================================================

    initial begin
        clk = 1'b0;

        forever
            #5 clk = ~clk;
    end


    // ============================================================
    // Monitor intermediate values
    // ============================================================

    always @(posedge clk) begin

        if (dut.tau_all_valid) begin

            $display("");
            $display("==============================================");
            $display("8 TX ARRIVAL TIMES VALID");
            $display("TIME = %0t", $time);
            $display("==============================================");

            $display("tau[0] = %h", dut.tau[0]);
            $display("tau[1] = %h", dut.tau[1]);
            $display("tau[2] = %h", dut.tau[2]);
            $display("tau[3] = %h", dut.tau[3]);
            $display("tau[4] = %h", dut.tau[4]);
            $display("tau[5] = %h", dut.tau[5]);
            $display("tau[6] = %h", dut.tau[6]);
            $display("tau[7] = %h", dut.tau[7]);

            $display("==============================================");

        end


        if (dut.sum_all_valid) begin

            $display("");
            $display("SUM OF 8 TX TIMES VALID");
            $display("TIME = %0t", $time);
            $display("sum_all = %h", dut.sum_all);

        end


        if (tx_time_valid) begin

            $display("");
            $display("==============================================");
            $display("FINAL TX TIME VALID");
            $display("TIME = %0t", $time);
            $display("TX_TIME HEX = %h", tx_time);
            $display("==============================================");

        end

    end


    // ============================================================
    // Test
    // ============================================================

    initial begin

        rst_n          = 1'b0;
        in_valid       = 1'b0;

        aperture_idx   = 5'd0;

        x_pixel        = 32'h00000000;
        z_pixel        = 32'h00000000;

        tx_delay_0     = 32'h00000000;
        tx_delay_1     = 32'h00000000;
        tx_delay_2     = 32'h00000000;
        tx_delay_3     = 32'h00000000;
        tx_delay_4     = 32'h00000000;
        tx_delay_5     = 32'h00000000;
        tx_delay_6     = 32'h00000000;
        tx_delay_7     = 32'h00000000;


        $display("");
        $display("==============================================");
        $display("       DAS TX TIME TEST");
        $display("==============================================");
        $display("Aperture : A0");
        $display("Elements : E0-E7");
        $display("Angle    : 40 deg");
        $display("Pixel    : x=0 mm, z=30 mm");
        $display("Clock    : 100 MHz");
        $display("==============================================");
        $display("");


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (10)
            @(posedge clk);

        rst_n = 1'b1;

        repeat (5)
            @(posedge clk);


        // ========================================================
        // A0 / 40 degree DLG delays
        //
        // Units = microseconds
        // ========================================================

        aperture_idx = 5'd0;

        tx_delay_0 = 32'h00000000;
        tx_delay_1 = 32'h3D800DA5;
        tx_delay_2 = 32'h3DFF1910;
        tx_delay_3 = 32'h3E3E8F3A;
        tx_delay_4 = 32'h3E7D0C61;
        tx_delay_5 = 32'h3E9D80BA;
        tx_delay_6 = 32'h3EBC35F6;
        tx_delay_7 = 32'h3EDAA4C9;


        // ========================================================
        // Pixel:
        //
        // x = 0.0 mm
        // z = 30.0 mm
        //
        // float32:
        // 0.0  = 00000000
        // 30.0 = 41F00000
        // ========================================================

        x_pixel = 32'h00000000;
        z_pixel = 32'h41F00000;


        // --------------------------------------------------------
        // Send one pixel
        // --------------------------------------------------------

        @(negedge clk);

        in_valid = 1'b1;

        $display(
            "INPUT VALID at time=%0t : A0, x=0, z=30",
            $time
        );


        @(negedge clk);

        in_valid = 1'b0;


        $display("");
        $display("Input sent.");
        $display("Waiting for TX pipeline...");
        $display("");


        // --------------------------------------------------------
        // Wait for complete pipeline
        // --------------------------------------------------------

        repeat (300)
            @(posedge clk);


        $display("");
        $display("==============================================");
        $display("SIMULATION FINISHED");
        $display("==============================================");
        $display("");

        $finish;

    end

endmodule