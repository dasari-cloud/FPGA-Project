`timescale 1ns / 1ps

module das_tof_tb;

    // ============================================================
    // Clock / reset
    // ============================================================

    reg clk;
    reg rst_n;
    reg in_valid;

    reg [31:0] tx_time;

    reg [31:0] rx_time_0;
    reg [31:0] rx_time_1;
    reg [31:0] rx_time_2;
    reg [31:0] rx_time_3;
    reg [31:0] rx_time_4;
    reg [31:0] rx_time_5;
    reg [31:0] rx_time_6;
    reg [31:0] rx_time_7;
    reg [31:0] rx_time_8;
    reg [31:0] rx_time_9;
    reg [31:0] rx_time_10;
    reg [31:0] rx_time_11;
    reg [31:0] rx_time_12;
    reg [31:0] rx_time_13;
    reg [31:0] rx_time_14;
    reg [31:0] rx_time_15;
    reg [31:0] rx_time_16;
    reg [31:0] rx_time_17;
    reg [31:0] rx_time_18;
    reg [31:0] rx_time_19;
    reg [31:0] rx_time_20;
    reg [31:0] rx_time_21;
    reg [31:0] rx_time_22;
    reg [31:0] rx_time_23;
    reg [31:0] rx_time_24;
    reg [31:0] rx_time_25;
    reg [31:0] rx_time_26;
    reg [31:0] rx_time_27;
    reg [31:0] rx_time_28;
    reg [31:0] rx_time_29;
    reg [31:0] rx_time_30;
    reg [31:0] rx_time_31;

    wire tof_valid;

    wire [31:0] tof_0;
    wire [31:0] tof_1;
    wire [31:0] tof_2;
    wire [31:0] tof_3;
    wire [31:0] tof_4;
    wire [31:0] tof_5;
    wire [31:0] tof_6;
    wire [31:0] tof_7;
    wire [31:0] tof_8;
    wire [31:0] tof_9;
    wire [31:0] tof_10;
    wire [31:0] tof_11;
    wire [31:0] tof_12;
    wire [31:0] tof_13;
    wire [31:0] tof_14;
    wire [31:0] tof_15;
    wire [31:0] tof_16;
    wire [31:0] tof_17;
    wire [31:0] tof_18;
    wire [31:0] tof_19;
    wire [31:0] tof_20;
    wire [31:0] tof_21;
    wire [31:0] tof_22;
    wire [31:0] tof_23;
    wire [31:0] tof_24;
    wire [31:0] tof_25;
    wire [31:0] tof_26;
    wire [31:0] tof_27;
    wire [31:0] tof_28;
    wire [31:0] tof_29;
    wire [31:0] tof_30;
    wire [31:0] tof_31;


    // ============================================================
    // DUT
    // ============================================================

    das_tof dut (

        .clk       (clk),
        .rst_n     (rst_n),

        .in_valid  (in_valid),

        .tx_time   (tx_time),

        .rx_time_0 (rx_time_0),
        .rx_time_1 (rx_time_1),
        .rx_time_2 (rx_time_2),
        .rx_time_3 (rx_time_3),
        .rx_time_4 (rx_time_4),
        .rx_time_5 (rx_time_5),
        .rx_time_6 (rx_time_6),
        .rx_time_7 (rx_time_7),
        .rx_time_8 (rx_time_8),
        .rx_time_9 (rx_time_9),
        .rx_time_10(rx_time_10),
        .rx_time_11(rx_time_11),
        .rx_time_12(rx_time_12),
        .rx_time_13(rx_time_13),
        .rx_time_14(rx_time_14),
        .rx_time_15(rx_time_15),
        .rx_time_16(rx_time_16),
        .rx_time_17(rx_time_17),
        .rx_time_18(rx_time_18),
        .rx_time_19(rx_time_19),
        .rx_time_20(rx_time_20),
        .rx_time_21(rx_time_21),
        .rx_time_22(rx_time_22),
        .rx_time_23(rx_time_23),
        .rx_time_24(rx_time_24),
        .rx_time_25(rx_time_25),
        .rx_time_26(rx_time_26),
        .rx_time_27(rx_time_27),
        .rx_time_28(rx_time_28),
        .rx_time_29(rx_time_29),
        .rx_time_30(rx_time_30),
        .rx_time_31(rx_time_31),

        .tof_valid (tof_valid),

        .tof_0     (tof_0),
        .tof_1     (tof_1),
        .tof_2     (tof_2),
        .tof_3     (tof_3),
        .tof_4     (tof_4),
        .tof_5     (tof_5),
        .tof_6     (tof_6),
        .tof_7     (tof_7),
        .tof_8     (tof_8),
        .tof_9     (tof_9),
        .tof_10    (tof_10),
        .tof_11    (tof_11),
        .tof_12    (tof_12),
        .tof_13    (tof_13),
        .tof_14    (tof_14),
        .tof_15    (tof_15),
        .tof_16    (tof_16),
        .tof_17    (tof_17),
        .tof_18    (tof_18),
        .tof_19    (tof_19),
        .tof_20    (tof_20),
        .tof_21    (tof_21),
        .tof_22    (tof_22),
        .tof_23    (tof_23),
        .tof_24    (tof_24),
        .tof_25    (tof_25),
        .tof_26    (tof_26),
        .tof_27    (tof_27),
        .tof_28    (tof_28),
        .tof_29    (tof_29),
        .tof_30    (tof_30),
        .tof_31    (tof_31)

    );


    // ============================================================
    // 100 MHz clock
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // Output monitor
    // ============================================================

    always @(posedge clk) begin

        if (tof_valid) begin

            $display("");
            $display("================================================");
            $display("32 TOTAL TOF VALUES VALID");
            $display("TIME = %0t", $time);
            $display("================================================");

            $display("TOF[00] = %h", tof_0);
            $display("TOF[01] = %h", tof_1);
            $display("TOF[02] = %h", tof_2);
            $display("TOF[03] = %h", tof_3);
            $display("TOF[04] = %h", tof_4);
            $display("TOF[05] = %h", tof_5);
            $display("TOF[06] = %h", tof_6);
            $display("TOF[07] = %h", tof_7);
            $display("TOF[08] = %h", tof_8);
            $display("TOF[09] = %h", tof_9);
            $display("TOF[10] = %h", tof_10);
            $display("TOF[11] = %h", tof_11);
            $display("TOF[12] = %h", tof_12);
            $display("TOF[13] = %h", tof_13);
            $display("TOF[14] = %h", tof_14);
            $display("TOF[15] = %h", tof_15);
            $display("TOF[16] = %h", tof_16);
            $display("TOF[17] = %h", tof_17);
            $display("TOF[18] = %h", tof_18);
            $display("TOF[19] = %h", tof_19);
            $display("TOF[20] = %h", tof_20);
            $display("TOF[21] = %h", tof_21);
            $display("TOF[22] = %h", tof_22);
            $display("TOF[23] = %h", tof_23);
            $display("TOF[24] = %h", tof_24);
            $display("TOF[25] = %h", tof_25);
            $display("TOF[26] = %h", tof_26);
            $display("TOF[27] = %h", tof_27);
            $display("TOF[28] = %h", tof_28);
            $display("TOF[29] = %h", tof_29);
            $display("TOF[30] = %h", tof_30);
            $display("TOF[31] = %h", tof_31);

            $display("================================================");
            $display("");

        end

    end


    // ============================================================
    // Test
    // ============================================================

    initial begin

        rst_n    = 1'b0;
        in_valid = 1'b0;

        tx_time = 32'h00000000;

        rx_time_0  = 0;
        rx_time_1  = 0;
        rx_time_2  = 0;
        rx_time_3  = 0;
        rx_time_4  = 0;
        rx_time_5  = 0;
        rx_time_6  = 0;
        rx_time_7  = 0;
        rx_time_8  = 0;
        rx_time_9  = 0;
        rx_time_10 = 0;
        rx_time_11 = 0;
        rx_time_12 = 0;
        rx_time_13 = 0;
        rx_time_14 = 0;
        rx_time_15 = 0;
        rx_time_16 = 0;
        rx_time_17 = 0;
        rx_time_18 = 0;
        rx_time_19 = 0;
        rx_time_20 = 0;
        rx_time_21 = 0;
        rx_time_22 = 0;
        rx_time_23 = 0;
        rx_time_24 = 0;
        rx_time_25 = 0;
        rx_time_26 = 0;
        rx_time_27 = 0;
        rx_time_28 = 0;
        rx_time_29 = 0;
        rx_time_30 = 0;
        rx_time_31 = 0;


        $display("");
        $display("================================================");
        $display("           DAS TOTAL TOF TEST");
        $display("================================================");
        $display("Pixel    : x=0 mm, z=30 mm");
        $display("TX       : A0 / 40 deg");
        $display("Clock    : 100 MHz");
        $display("================================================");
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
        // Verified TX time
        //
        // 0x40A33FBB = approximately 5.10153 us
        // ========================================================

        tx_time = 32'h40A33FBB;


        // ========================================================
        // Verified RX times from das_delay
        //
        // Pixel x = 0 mm
        // Pixel z = 30 mm
        // ========================================================

        rx_time_0  = 32'h409F07B2;
        rx_time_1  = 32'h409E283B;
        rx_time_2  = 32'h409D568B;
        rx_time_3  = 32'h409C92D9;
        rx_time_4  = 32'h409BDD5B;
        rx_time_5  = 32'h409B3643;
        rx_time_6  = 32'h409A9DBF;
        rx_time_7  = 32'h409A13FA;

        rx_time_8  = 32'h4099991C;
        rx_time_9  = 32'h40992D49;
        rx_time_10 = 32'h4098D0A1;
        rx_time_11 = 32'h4098833F;
        rx_time_12 = 32'h4098453B;
        rx_time_13 = 32'h409816A7;
        rx_time_14 = 32'h4097F792;
        rx_time_15 = 32'h4097E805;

        rx_time_16 = 32'h4097E805;
        rx_time_17 = 32'h4097F792;
        rx_time_18 = 32'h409816A7;
        rx_time_19 = 32'h4098453B;
        rx_time_20 = 32'h4098833F;
        rx_time_21 = 32'h4098D0A1;
        rx_time_22 = 32'h40992D49;
        rx_time_23 = 32'h4099991C;

        rx_time_24 = 32'h409A13FA;
        rx_time_25 = 32'h409A9DBF;
        rx_time_26 = 32'h409B3643;
        rx_time_27 = 32'h409BDD5B;
        rx_time_28 = 32'h409C92D9;
        rx_time_29 = 32'h409D568B;
        rx_time_30 = 32'h409E283B;
        rx_time_31 = 32'h409F07B2;


        // --------------------------------------------------------
        // Send one aligned TX/RX set
        // --------------------------------------------------------

        @(negedge clk);

        in_valid = 1'b1;

        $display(
            "INPUT VALID : TIME=%0t : TX + 32 RX",
            $time
        );


        @(negedge clk);

        in_valid = 1'b0;


        // --------------------------------------------------------
        // Wait
        // --------------------------------------------------------

        repeat (100)
            @(posedge clk);


        $display("");
        $display("================================================");
        $display("SIMULATION FINISHED");
        $display("================================================");

        $finish;

    end

endmodule