`timescale 1ns / 1ps

// ============================================================================
// DIFFERENTIAL CHECK: das_tx_time (original) vs das_tx_time_cached
//
// Reference case (matches the main image TB's precompute ordering):
//   theta_idx = 0, aperture_idx = 0  -->  event 0
//   pixel: x = 0.0 mm, z = 30.0 mm
//   expected original TX_TIME = 32'h40A33FBB
//
// This does NOT hand-type any DLG delay constants. It drives SAG+DLG for
// event 0 exactly like the main TB's precompute loop, captures the real
// delay set, then feeds the SAME delays + SAME pixel into das_delay,
// das_tx_time (original) and das_tx_time_cached, and compares:
//
//   1) original tx_time   vs golden 32'h40A33FBB   (sanity on this harness)
//   2) original tx_time   vs cached   tx_time      (the actual claim)
//
// If (2) passes, DAS output downstream is guaranteed identical too, since
// das_tof/sample_index/rf_read/adder are untouched and only ever see
// tx_time as their TX-side input.
// ============================================================================

module das_tx_time_cached_check_tb;

    reg clk;
    reg rst_n;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // SAG + DLG -- reproduce event 0's real delay set
    // ------------------------------------------------------------
    reg        angle_valid;
    reg [1:0]  theta_idx;
    reg [4:0]  aperture_idx;
    reg [31:0] focus;

    wire        trig_valid;
    wire [31:0] sin_theta, cos_theta;
    wire        focal_valid;
    wire [31:0] x_focus, z_focus;
    wire        distances_valid;
    wire [31:0] distance [0:7];
    wire        dmax_valid;
    wire [31:0] d_max;
    wire        delta_valid;
    wire [31:0] delta_d [0:7];
    wire        delay_valid;
    wire [31:0] dlg_delay [0:7];

    SAG u_sag (
        .clk(clk), .rst_n(rst_n),
        .angle_valid(angle_valid), .theta_idx(theta_idx),
        .trig_valid(trig_valid), .sin_theta(sin_theta), .cos_theta(cos_theta)
    );

    DLG u_dlg (
        .clk(clk), .rst_n(rst_n),
        .in_valid(trig_valid),
        .aperture_idx(aperture_idx),
        .focus(focus),
        .sin_theta(sin_theta), .cos_theta(cos_theta),
        .focal_valid(focal_valid), .x_focus(x_focus), .z_focus(z_focus),
        .distances_valid(distances_valid),
        .distance_0(distance[0]), .distance_1(distance[1]),
        .distance_2(distance[2]), .distance_3(distance[3]),
        .distance_4(distance[4]), .distance_5(distance[5]),
        .distance_6(distance[6]), .distance_7(distance[7]),
        .dmax_valid(dmax_valid), .d_max(d_max),
        .delta_valid(delta_valid),
        .delta_d0(delta_d[0]), .delta_d1(delta_d[1]),
        .delta_d2(delta_d[2]), .delta_d3(delta_d[3]),
        .delta_d4(delta_d[4]), .delta_d5(delta_d[5]),
        .delta_d6(delta_d[6]), .delta_d7(delta_d[7]),
        .delay_valid(delay_valid),
        .delay_0(dlg_delay[0]), .delay_1(dlg_delay[1]),
        .delay_2(dlg_delay[2]), .delay_3(dlg_delay[3]),
        .delay_4(dlg_delay[4]), .delay_5(dlg_delay[5]),
        .delay_6(dlg_delay[6]), .delay_7(dlg_delay[7])
    );

    reg [31:0] tx_delay [0:7];
    integer jj;

    // ------------------------------------------------------------
    // das_delay (RX, all 32 lanes) for the reference pixel
    // ------------------------------------------------------------
    reg        pixel_valid;
    reg [31:0] x_pixel, z_pixel;
    wire       rx_time_valid;
    wire [31:0] rx_time [0:31];

    das_delay u_rx_delay (
        .clk(clk), .rst_n(rst_n),
        .pixel_valid(pixel_valid),
        .x_pixel(x_pixel), .z_pixel(z_pixel),
        .rx_time_valid(rx_time_valid),
        .rx_time_0(rx_time[0]),   .rx_time_1(rx_time[1]),
        .rx_time_2(rx_time[2]),   .rx_time_3(rx_time[3]),
        .rx_time_4(rx_time[4]),   .rx_time_5(rx_time[5]),
        .rx_time_6(rx_time[6]),   .rx_time_7(rx_time[7]),
        .rx_time_8(rx_time[8]),   .rx_time_9(rx_time[9]),
        .rx_time_10(rx_time[10]), .rx_time_11(rx_time[11]),
        .rx_time_12(rx_time[12]), .rx_time_13(rx_time[13]),
        .rx_time_14(rx_time[14]), .rx_time_15(rx_time[15]),
        .rx_time_16(rx_time[16]), .rx_time_17(rx_time[17]),
        .rx_time_18(rx_time[18]), .rx_time_19(rx_time[19]),
        .rx_time_20(rx_time[20]), .rx_time_21(rx_time[21]),
        .rx_time_22(rx_time[22]), .rx_time_23(rx_time[23]),
        .rx_time_24(rx_time[24]), .rx_time_25(rx_time[25]),
        .rx_time_26(rx_time[26]), .rx_time_27(rx_time[27]),
        .rx_time_28(rx_time[28]), .rx_time_29(rx_time[29]),
        .rx_time_30(rx_time[30]), .rx_time_31(rx_time[31])
    );

    // ------------------------------------------------------------
    // ORIGINAL das_tx_time
    // ------------------------------------------------------------
    reg start_valid;
    wire tx_time_valid_orig;
    wire [31:0] tx_time_orig;

    das_tx_time u_tx_time_orig (
        .clk(clk), .rst_n(rst_n),
        .in_valid(start_valid),
        .aperture_idx(aperture_idx),
        .x_pixel(x_pixel), .z_pixel(z_pixel),
        .tx_delay_0(tx_delay[0]), .tx_delay_1(tx_delay[1]),
        .tx_delay_2(tx_delay[2]), .tx_delay_3(tx_delay[3]),
        .tx_delay_4(tx_delay[4]), .tx_delay_5(tx_delay[5]),
        .tx_delay_6(tx_delay[6]), .tx_delay_7(tx_delay[7]),
        .tx_time_valid(tx_time_valid_orig), .tx_time(tx_time_orig)
    );

    // ------------------------------------------------------------
    // CACHED das_tx_time_cached
    // ------------------------------------------------------------
    reg cache_valid;
    wire tx_time_valid_cached;
    wire [31:0] tx_time_cached;

    das_tx_time_cached u_tx_time_cached (
        .clk(clk), .rst_n(rst_n),
        .in_valid(cache_valid),
        .aperture_idx(aperture_idx),
        .rx_time_0(rx_time[0]),   .rx_time_1(rx_time[1]),
        .rx_time_2(rx_time[2]),   .rx_time_3(rx_time[3]),
        .rx_time_4(rx_time[4]),   .rx_time_5(rx_time[5]),
        .rx_time_6(rx_time[6]),   .rx_time_7(rx_time[7]),
        .rx_time_8(rx_time[8]),   .rx_time_9(rx_time[9]),
        .rx_time_10(rx_time[10]), .rx_time_11(rx_time[11]),
        .rx_time_12(rx_time[12]), .rx_time_13(rx_time[13]),
        .rx_time_14(rx_time[14]), .rx_time_15(rx_time[15]),
        .rx_time_16(rx_time[16]), .rx_time_17(rx_time[17]),
        .rx_time_18(rx_time[18]), .rx_time_19(rx_time[19]),
        .rx_time_20(rx_time[20]), .rx_time_21(rx_time[21]),
        .rx_time_22(rx_time[22]), .rx_time_23(rx_time[23]),
        .rx_time_24(rx_time[24]), .rx_time_25(rx_time[25]),
        .rx_time_26(rx_time[26]), .rx_time_27(rx_time[27]),
        .rx_time_28(rx_time[28]), .rx_time_29(rx_time[29]),
        .rx_time_30(rx_time[30]), .rx_time_31(rx_time[31]),
        .tx_delay_0(tx_delay[0]), .tx_delay_1(tx_delay[1]),
        .tx_delay_2(tx_delay[2]), .tx_delay_3(tx_delay[3]),
        .tx_delay_4(tx_delay[4]), .tx_delay_5(tx_delay[5]),
        .tx_delay_6(tx_delay[6]), .tx_delay_7(tx_delay[7]),
        .tx_time_valid(tx_time_valid_cached), .tx_time(tx_time_cached)
    );

    localparam [31:0] GOLDEN_TX_TIME = 32'h40A33FBB;

    initial begin
        rst_n        = 1'b0;
        angle_valid  = 1'b0;
        pixel_valid  = 1'b0;
        start_valid  = 1'b0;
        cache_valid  = 1'b0;
        theta_idx    = 2'd0;
        aperture_idx = 5'd0;
        focus        = 32'h42820000;   // 65.0 mm
        x_pixel      = 32'h00000000;   // 0.0 mm
        z_pixel      = 32'h41F00000;   // 30.0 mm

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        // ---- Step 1: get event-0 DLG delays ----
        @(negedge clk);
        angle_valid = 1'b1;
        @(negedge clk);
        angle_valid = 1'b0;
        wait (delay_valid == 1'b1);
        #1;
        for (jj = 0; jj < 8; jj = jj + 1)
            tx_delay[jj] = dlg_delay[jj];

        $display("Captured event-0 DLG delays.");

        // ---- Step 2: RX cache for the reference pixel ----
        @(negedge clk);
        pixel_valid = 1'b1;
        @(negedge clk);
        pixel_valid = 1'b0;
        wait (rx_time_valid == 1'b1);
        #1;

        $display("RX cache ready (32 lanes).");

        // ---- Step 3: original TX ----
        @(negedge clk);
        start_valid = 1'b1;
        @(negedge clk);
        start_valid = 1'b0;
        wait (tx_time_valid_orig == 1'b1);
        #1;

        // ---- Step 4: cached TX, same aperture/delays/rx cache ----
        @(negedge clk);
        cache_valid = 1'b1;
        @(negedge clk);
        cache_valid = 1'b0;
        wait (tx_time_valid_cached == 1'b1);
        #1;

        $display("");
        $display("============================================================");
        $display("Original  tx_time = %h", tx_time_orig);
        $display("Golden    tx_time = %h", GOLDEN_TX_TIME);
        $display("Cached    tx_time = %h", tx_time_cached);
        $display("============================================================");

        if (tx_time_orig !== GOLDEN_TX_TIME)
            $display("WARNING: original module did not match your known golden value -- check aperture/theta/focus setup in this harness.");
        else
            $display("PASS (1/2): original module reproduces golden 40A33FBB.");

        if (tx_time_cached === tx_time_orig)
            $display("PASS (2/2): cached module is BIT-EXACT with original. Safe to swap in.");
        else
            $display("FAIL (2/2): cached module MISMATCHES original -- do not swap in yet.");

        $display("");
        $finish;
    end

endmodule
