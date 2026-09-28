`timescale 1ns / 1ps

module das_delay_tb;

    // ============================================================
    // Clock / Reset
    // ============================================================

    reg clk;
    reg rst_n;

    reg        pixel_valid;
    reg [31:0] x_pixel;
    reg [31:0] z_pixel;

    wire       rx_time_valid;

    wire [31:0] rx_time_0;
    wire [31:0] rx_time_1;
    wire [31:0] rx_time_2;
    wire [31:0] rx_time_3;
    wire [31:0] rx_time_4;
    wire [31:0] rx_time_5;
    wire [31:0] rx_time_6;
    wire [31:0] rx_time_7;
    wire [31:0] rx_time_8;
    wire [31:0] rx_time_9;
    wire [31:0] rx_time_10;
    wire [31:0] rx_time_11;
    wire [31:0] rx_time_12;
    wire [31:0] rx_time_13;
    wire [31:0] rx_time_14;
    wire [31:0] rx_time_15;
    wire [31:0] rx_time_16;
    wire [31:0] rx_time_17;
    wire [31:0] rx_time_18;
    wire [31:0] rx_time_19;
    wire [31:0] rx_time_20;
    wire [31:0] rx_time_21;
    wire [31:0] rx_time_22;
    wire [31:0] rx_time_23;
    wire [31:0] rx_time_24;
    wire [31:0] rx_time_25;
    wire [31:0] rx_time_26;
    wire [31:0] rx_time_27;
    wire [31:0] rx_time_28;
    wire [31:0] rx_time_29;
    wire [31:0] rx_time_30;
    wire [31:0] rx_time_31;


    // ============================================================
    // DUT
    // ============================================================

    das_delay dut (

        .clk            (clk),
        .rst_n          (rst_n),

        .pixel_valid    (pixel_valid),
        .x_pixel        (x_pixel),
        .z_pixel        (z_pixel),

        .rx_time_valid  (rx_time_valid),

        .rx_time_0      (rx_time_0),
        .rx_time_1      (rx_time_1),
        .rx_time_2      (rx_time_2),
        .rx_time_3      (rx_time_3),
        .rx_time_4      (rx_time_4),
        .rx_time_5      (rx_time_5),
        .rx_time_6      (rx_time_6),
        .rx_time_7      (rx_time_7),
        .rx_time_8      (rx_time_8),
        .rx_time_9      (rx_time_9),
        .rx_time_10     (rx_time_10),
        .rx_time_11     (rx_time_11),
        .rx_time_12     (rx_time_12),
        .rx_time_13     (rx_time_13),
        .rx_time_14     (rx_time_14),
        .rx_time_15     (rx_time_15),
        .rx_time_16     (rx_time_16),
        .rx_time_17     (rx_time_17),
        .rx_time_18     (rx_time_18),
        .rx_time_19     (rx_time_19),
        .rx_time_20     (rx_time_20),
        .rx_time_21     (rx_time_21),
        .rx_time_22     (rx_time_22),
        .rx_time_23     (rx_time_23),
        .rx_time_24     (rx_time_24),
        .rx_time_25     (rx_time_25),
        .rx_time_26     (rx_time_26),
        .rx_time_27     (rx_time_27),
        .rx_time_28     (rx_time_28),
        .rx_time_29     (rx_time_29),
        .rx_time_30     (rx_time_30),
        .rx_time_31     (rx_time_31)

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
    // Count inputs / outputs
    // ============================================================

    integer input_count;
    integer output_count;

    time previous_output_time;


    // ============================================================
    // Input stimulus
    // ============================================================

    initial begin

        rst_n                = 1'b0;
        pixel_valid          = 1'b0;

        x_pixel              = 32'h00000000;
        z_pixel              = 32'h00000000;

        input_count          = 0;
        output_count         = 0;

        previous_output_time = 0;


        $display("");
        $display("==============================================");
        $display("     DAS DELAY - 32 RX PARALLEL TEST");
        $display("==============================================");
        $display("Clock = 100 MHz");
        $display("Testing 3 pixels back-to-back");
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
        // Pixel 0
        //
        // x = 0.0 mm
        // z = 30.0 mm
        //
        // 0.0  = 00000000
        // 30.0 = 41F00000
        // ========================================================

        @(negedge clk);

        pixel_valid = 1'b1;

        x_pixel = 32'h00000000;
        z_pixel = 32'h41F00000;

        input_count = input_count + 1;

        $display(
            "INPUT %0d  time=%0t  x=0.0 mm  z=30.0 mm",
            input_count,
            $time
        );


        // ========================================================
        // Pixel 1
        //
        // x = +3.0 mm
        // z = 40.0 mm
        //
        // 3.0  = 40400000
        // 40.0 = 42200000
        // ========================================================

        @(negedge clk);

        x_pixel = 32'h40400000;
        z_pixel = 32'h42200000;

        input_count = input_count + 1;

        $display(
            "INPUT %0d  time=%0t  x=3.0 mm  z=40.0 mm",
            input_count,
            $time
        );


        // ========================================================
        // Pixel 2
        //
        // x = -5.0 mm
        // z = 50.0 mm
        //
        // -5.0 = C0A00000
        // 50.0 = 42480000
        // ========================================================

        @(negedge clk);

        x_pixel = 32'hC0A00000;
        z_pixel = 32'h42480000;

        input_count = input_count + 1;

        $display(
            "INPUT %0d  time=%0t  x=-5.0 mm  z=50.0 mm",
            input_count,
            $time
        );


        // --------------------------------------------------------
        // Stop sending pixels
        // --------------------------------------------------------

        @(negedge clk);

        pixel_valid = 1'b0;

        x_pixel = 32'h00000000;
        z_pixel = 32'h00000000;


        $display("");
        $display("All input pixels sent.");
        $display("Waiting for DAS delay pipeline...");
        $display("");


        // --------------------------------------------------------
        // Wait long enough for pipeline
        // --------------------------------------------------------

        repeat (300)
            @(posedge clk);


        // ========================================================
        // Final report
        // ========================================================

        $display("");
        $display("==============================================");
        $display("FINAL REPORT");
        $display("==============================================");

        $display("INPUT PIXELS  = %0d", input_count);
        $display("OUTPUT PIXELS = %0d", output_count);

        if (output_count == input_count)
            $display("COUNT CHECK   = PASS");
        else
            $display("COUNT CHECK   = FAIL");

        $display("==============================================");
        $display("");

        $finish;

    end


    // ============================================================
    // Output monitor
    // ============================================================

    always @(posedge clk) begin

        if (rx_time_valid) begin

            output_count = output_count + 1;

            $display("");
            $display("----------------------------------------------");
            $display(
                "OUTPUT %0d  time=%0t",
                output_count,
                $time
            );

            // Check output spacing after first output
            if (previous_output_time != 0) begin

                if (($time - previous_output_time) == 10000)
                    $display("Output gap = 10 ns : PASS");
                else
                    $display(
                        "Output gap = %0t : CHECK",
                        $time - previous_output_time
                    );

            end

            previous_output_time = $time;


            // ----------------------------------------------------
            // Print all 32 RX times in HEX
            // ----------------------------------------------------

            $display("RX00 = %h", rx_time_0);
            $display("RX01 = %h", rx_time_1);
            $display("RX02 = %h", rx_time_2);
            $display("RX03 = %h", rx_time_3);
            $display("RX04 = %h", rx_time_4);
            $display("RX05 = %h", rx_time_5);
            $display("RX06 = %h", rx_time_6);
            $display("RX07 = %h", rx_time_7);

            $display("RX08 = %h", rx_time_8);
            $display("RX09 = %h", rx_time_9);
            $display("RX10 = %h", rx_time_10);
            $display("RX11 = %h", rx_time_11);
            $display("RX12 = %h", rx_time_12);
            $display("RX13 = %h", rx_time_13);
            $display("RX14 = %h", rx_time_14);
            $display("RX15 = %h", rx_time_15);

            $display("RX16 = %h", rx_time_16);
            $display("RX17 = %h", rx_time_17);
            $display("RX18 = %h", rx_time_18);
            $display("RX19 = %h", rx_time_19);
            $display("RX20 = %h", rx_time_20);
            $display("RX21 = %h", rx_time_21);
            $display("RX22 = %h", rx_time_22);
            $display("RX23 = %h", rx_time_23);

            $display("RX24 = %h", rx_time_24);
            $display("RX25 = %h", rx_time_25);
            $display("RX26 = %h", rx_time_26);
            $display("RX27 = %h", rx_time_27);
            $display("RX28 = %h", rx_time_28);
            $display("RX29 = %h", rx_time_29);
            $display("RX30 = %h", rx_time_30);
            $display("RX31 = %h", rx_time_31);

        end

    end

endmodule