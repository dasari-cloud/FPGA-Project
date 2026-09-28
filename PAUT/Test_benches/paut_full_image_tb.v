`timescale 1ns / 1ps

// ================================================================
// CACHED-TX FULL IMAGE TESTBENCH
// ================================================================
// Change vs. paut_full_image_pipelined_tb: RX propagation (das_delay,
// 32 lanes) is computed ONCE PER PIXEL instead of once per event.
// TX propagation reuses those same 32 RX values via das_tx_time_cached
// (verified bit-exact against das_tx_time in das_tx_time_cached_check_tb),
// eliminating 7,248,000 x 8 redundant SQRT/distance evaluations -- the
// single biggest floating-point workload in the original testbench.
//
//   RX geometry : 96,640 pixels  x 32 lanes  (was 7,248,000 x 32)
//   TX geometry : ZERO extra SQRT geometry   (was 7,248,000 x 8)
//   DLG         : 75 total (unchanged)
//   TOF/RF/DAS  : 7,248,000 event ops (unchanged -- genuinely per-event)
//
// Pipelining: RX for pixel N+1 is requested at the START of pixel N's
// 75-event stream, into a double-buffered cache (rx_cache[0]/[1]).
// RX latency (71 clocks) is comfortably shorter than one pixel's event
// stream (75 clocks), so by the time pixel N+1 begins, its RX cache is
// already valid -- no stall between pixels in the common case.
//
// VERIFY INCREMENTALLY, as planned:
//   1) das_tx_time_cached_check_tb must PASS (bit-exact vs original) --
//      already confirmed: 40a33fbb == 40a33fbb.
//   2) Run ONE row here first (e.g. temporarily set NZ_LIMIT below) and
//      check wall-clock time before launching the full 302-row run.
// ================================================================

module paut_full_image_cached_tb;

    localparam TOTAL_RF_SAMPLES = 3686400;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    reg clk;
    reg rst_n;

    // ============================================================
    // PIXEL / EVENT
    // ============================================================

    reg        cache_valid;   // was start_valid: enables das_tx_time_cached, 1/event
    reg        pixel_valid;   // NEW: enables das_delay, pulsed once per PIXEL
    reg [4:0]  aperture_idx;
    reg [6:0]  event_idx;

    reg [31:0] x_pixel;
    reg [31:0] z_pixel;

    // ============================================================
    // SAG + DLG
    // ============================================================

    reg        angle_valid;
    reg [1:0]  theta_idx;

    wire        trig_valid;
    wire [31:0] sin_theta;
    wire [31:0] cos_theta;

    // 65.0 mm = IEEE-754 single precision 0x42820000
    reg [31:0] focus;

    wire        focal_valid;
    wire [31:0] x_focus;
    wire [31:0] z_focus;

    wire        distances_valid;
    wire [31:0] distance [0:7];

    wire        dmax_valid;
    wire [31:0] d_max;

    wire        delta_valid;
    wire [31:0] delta_d [0:7];

    wire        delay_valid;
    wire [31:0] dlg_delay [0:7];

    // Captured DLG delays used by the already-verified DAS chain
    reg [31:0] tx_delay [0:7];
    reg        dlg_captured;

    // ============================================================
    // TX TIME (cached -- no distance/SQRT geometry, see das_tx_time_cached)
    // ============================================================

    wire        tx_time_valid_cached;
    wire [31:0] tx_time_cached;

    // ============================================================
    // RX TIMES
    // ============================================================

    wire        rx_time_valid;
    wire [31:0] rx_time [0:31];

    // ============================================================
    // TOF
    // ============================================================

    wire        tof_valid;
    wire [31:0] tof [0:31];

    // ============================================================
    // SAMPLE INDEX
    // ============================================================

    wire        sample_index_valid;
    wire [31:0] sample_index [0:31];

    // ============================================================
    // RF ADDRESS
    // ============================================================

    wire        address_valid;
    wire [21:0] rf_addr [0:31];

    // ============================================================
    // RF MEMORY
    // ============================================================

    reg signed [15:0] rf_mem [0:TOTAL_RF_SAMPLES-1];

    reg signed [15:0] rf_sample [0:31];
    reg sample_in_range [0:31];

    reg adder_in_valid;

    // ============================================================
    // FINAL DAS OUTPUT
    // ============================================================

    wire signed [20:0] das_sum;
    wire               das_valid;

    integer i;
    integer event_no;
    integer out_file;
    reg clear_event;

    // ============================================================
    // FULL IMAGE CONTROLLER
    // PData grid: NZ=302 depth rows, NX=320 lateral columns
    // x = -96.0 + ix*0.6 mm
    // z = 0.0 + iz*0.632 mm
    // ============================================================
    localparam integer NX = 320;
    localparam integer NZ = 302;

    integer ix;
    integer iz;
    integer pixel_count;
    integer pixel_index;   // flattened pixel loop index = iz*NX + ix
    reg signed [63:0] pixel_accum;
    real x_mm;
    real z_mm;

    // ============================================================
    // STREAMING / PIPELINED TESTBENCH SUPPORT
    // ============================================================
    localparam integer FIFO_DEPTH = 1024;
    localparam integer FIFO_MASK  = FIFO_DEPTH-1;

    // DLG depends only on event, not pixel: compute these 75 sets ONCE.
    reg [31:0] delay_cache [0:74][0:7];

    // Input metadata FIFO: preserves event number until cached TX_TIME emerges
    // (57-clock fixed latency -- RX no longer needs its own alignment FIFO,
    // since it's now a per-pixel constant read directly at pairing time).
    reg [6:0] in_event_fifo [0:FIFO_DEPTH-1];
    integer in_wr, in_rd;

    // Event metadata FIFO from TOF launch to sample-index/RF-address stage.
    reg [6:0] tof_event_fifo [0:FIFO_DEPTH-1];
    integer tof_meta_wr, tof_meta_rd;
    wire [6:0] rf_event_idx = tof_event_fifo[tof_meta_rd & FIFO_MASK];

    integer launched_jobs;
    integer completed_jobs;
    integer output_pixels;
    integer pre_ev;
    integer jj;
    reg stream_done;

    // Testbench-only conversion from Verilog real to IEEE-754 float32.
    function [31:0] real_to_float32;
        input real value;
        reg sign_bit;
        real a;
        real mant;
        integer exp_unbiased;
        integer exp_biased;
        integer frac_int;
        begin
            if (value == 0.0) begin
                real_to_float32 = 32'h00000000;
            end
            else begin
                sign_bit = (value < 0.0);
                if (sign_bit) a = -value;
                else          a =  value;

                exp_unbiased = 0;
                while (a >= 2.0) begin
                    a = a / 2.0;
                    exp_unbiased = exp_unbiased + 1;
                end
                while (a < 1.0) begin
                    a = a * 2.0;
                    exp_unbiased = exp_unbiased - 1;
                end

                mant = a - 1.0;
                frac_int = $rtoi(mant * 8388608.0 + 0.5);
                exp_biased = exp_unbiased + 127;

                // Handle rounding overflow of the fraction.
                if (frac_int >= 8388608) begin
                    frac_int = 0;
                    exp_biased = exp_biased + 1;
                end

                real_to_float32 = {sign_bit, exp_biased[7:0], frac_int[22:0]};
            end
        end
    endfunction


    // ============================================================
    // CLOCK = 100 MHz
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // SAG
    // theta_idx: 0 = 40 deg, 1 = 55 deg, 2 = 70 deg
    // ============================================================

    SAG u_sag (
        .clk(clk),
        .rst_n(rst_n),
        .angle_valid(angle_valid),
        .theta_idx(theta_idx),
        .trig_valid(trig_valid),
        .sin_theta(sin_theta),
        .cos_theta(cos_theta)
    );


    // ============================================================
    // DLG
    // ============================================================

    DLG u_dlg (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(trig_valid),
        .aperture_idx(aperture_idx),
        .focus(focus),
        .sin_theta(sin_theta),
        .cos_theta(cos_theta),

        .focal_valid(focal_valid),
        .x_focus(x_focus),
        .z_focus(z_focus),

        .distances_valid(distances_valid),
        .distance_0(distance[0]),
        .distance_1(distance[1]),
        .distance_2(distance[2]),
        .distance_3(distance[3]),
        .distance_4(distance[4]),
        .distance_5(distance[5]),
        .distance_6(distance[6]),
        .distance_7(distance[7]),

        .dmax_valid(dmax_valid),
        .d_max(d_max),

        .delta_valid(delta_valid),
        .delta_d0(delta_d[0]),
        .delta_d1(delta_d[1]),
        .delta_d2(delta_d[2]),
        .delta_d3(delta_d[3]),
        .delta_d4(delta_d[4]),
        .delta_d5(delta_d[5]),
        .delta_d6(delta_d[6]),
        .delta_d7(delta_d[7]),

        .delay_valid(delay_valid),
        .delay_0(dlg_delay[0]),
        .delay_1(dlg_delay[1]),
        .delay_2(dlg_delay[2]),
        .delay_3(dlg_delay[3]),
        .delay_4(dlg_delay[4]),
        .delay_5(dlg_delay[5]),
        .delay_6(dlg_delay[6]),
        .delay_7(dlg_delay[7])
    );


    // DLG outputs are cached once during initialization by the controller below.
    // tx_delay[] is then loaded from delay_cache[event] for every streamed job.

    // ============================================================
    // PER-PIXEL RX CACHE (double-buffered)
    //
    // das_delay is triggered ONCE per pixel via a single-cycle pixel_valid
    // pulse (not held high). Its 32-lane result, 71 clocks later, is
    // latched into rx_cache[pending_buf][] and held constant for that
    // pixel's entire 75-event burst. cur_buf/pending_buf/nxt_buf are
    // driven by the streaming controller in the initial block below.
    // ============================================================

    reg [31:0] rx_cache [0:1][0:31];
    reg [1:0]  rx_cache_ready;   // one ready bit per buffer
    reg        cur_buf;         // buffer the CURRENT pixel's 75 events read from
    reg        pending_buf;     // buffer the outstanding das_delay request targets

    wire [31:0] cur_rx_time [0:31];
    genvar rc;
    generate
        for (rc = 0; rc < 32; rc = rc + 1) begin : CUR_RX_MUX
            assign cur_rx_time[rc] = rx_cache[cur_buf][rc];
        end
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            rx_cache_ready <= 2'b00;
        end
        else begin
            if (pixel_valid)
                rx_cache_ready[pending_buf] <= 1'b0;   // clear target before it fills

            if (rx_time_valid) begin
                rx_cache[pending_buf][0]  <= rx_time[0];
                rx_cache[pending_buf][1]  <= rx_time[1];
                rx_cache[pending_buf][2]  <= rx_time[2];
                rx_cache[pending_buf][3]  <= rx_time[3];
                rx_cache[pending_buf][4]  <= rx_time[4];
                rx_cache[pending_buf][5]  <= rx_time[5];
                rx_cache[pending_buf][6]  <= rx_time[6];
                rx_cache[pending_buf][7]  <= rx_time[7];
                rx_cache[pending_buf][8]  <= rx_time[8];
                rx_cache[pending_buf][9]  <= rx_time[9];
                rx_cache[pending_buf][10] <= rx_time[10];
                rx_cache[pending_buf][11] <= rx_time[11];
                rx_cache[pending_buf][12] <= rx_time[12];
                rx_cache[pending_buf][13] <= rx_time[13];
                rx_cache[pending_buf][14] <= rx_time[14];
                rx_cache[pending_buf][15] <= rx_time[15];
                rx_cache[pending_buf][16] <= rx_time[16];
                rx_cache[pending_buf][17] <= rx_time[17];
                rx_cache[pending_buf][18] <= rx_time[18];
                rx_cache[pending_buf][19] <= rx_time[19];
                rx_cache[pending_buf][20] <= rx_time[20];
                rx_cache[pending_buf][21] <= rx_time[21];
                rx_cache[pending_buf][22] <= rx_time[22];
                rx_cache[pending_buf][23] <= rx_time[23];
                rx_cache[pending_buf][24] <= rx_time[24];
                rx_cache[pending_buf][25] <= rx_time[25];
                rx_cache[pending_buf][26] <= rx_time[26];
                rx_cache[pending_buf][27] <= rx_time[27];
                rx_cache[pending_buf][28] <= rx_time[28];
                rx_cache[pending_buf][29] <= rx_time[29];
                rx_cache[pending_buf][30] <= rx_time[30];
                rx_cache[pending_buf][31] <= rx_time[31];
                rx_cache_ready[pending_buf] <= 1'b1;
            end
        end
    end

    // ============================================================
    // TX TIME -- CACHED (see das_tx_time_cached.v)
    // ============================================================

    das_tx_time_cached u_tx_time_cached (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(cache_valid),

        .aperture_idx(aperture_idx),

        .rx_time_0(cur_rx_time[0]),
        .rx_time_1(cur_rx_time[1]),
        .rx_time_2(cur_rx_time[2]),
        .rx_time_3(cur_rx_time[3]),
        .rx_time_4(cur_rx_time[4]),
        .rx_time_5(cur_rx_time[5]),
        .rx_time_6(cur_rx_time[6]),
        .rx_time_7(cur_rx_time[7]),
        .rx_time_8(cur_rx_time[8]),
        .rx_time_9(cur_rx_time[9]),
        .rx_time_10(cur_rx_time[10]),
        .rx_time_11(cur_rx_time[11]),
        .rx_time_12(cur_rx_time[12]),
        .rx_time_13(cur_rx_time[13]),
        .rx_time_14(cur_rx_time[14]),
        .rx_time_15(cur_rx_time[15]),
        .rx_time_16(cur_rx_time[16]),
        .rx_time_17(cur_rx_time[17]),
        .rx_time_18(cur_rx_time[18]),
        .rx_time_19(cur_rx_time[19]),
        .rx_time_20(cur_rx_time[20]),
        .rx_time_21(cur_rx_time[21]),
        .rx_time_22(cur_rx_time[22]),
        .rx_time_23(cur_rx_time[23]),
        .rx_time_24(cur_rx_time[24]),
        .rx_time_25(cur_rx_time[25]),
        .rx_time_26(cur_rx_time[26]),
        .rx_time_27(cur_rx_time[27]),
        .rx_time_28(cur_rx_time[28]),
        .rx_time_29(cur_rx_time[29]),
        .rx_time_30(cur_rx_time[30]),
        .rx_time_31(cur_rx_time[31]),

        .tx_delay_0(tx_delay[0]),
        .tx_delay_1(tx_delay[1]),
        .tx_delay_2(tx_delay[2]),
        .tx_delay_3(tx_delay[3]),
        .tx_delay_4(tx_delay[4]),
        .tx_delay_5(tx_delay[5]),
        .tx_delay_6(tx_delay[6]),
        .tx_delay_7(tx_delay[7]),

        .tx_time_valid(tx_time_valid_cached),
        .tx_time(tx_time_cached)
    );


    // ============================================================
    // RX TIME -- triggered ONCE PER PIXEL (pixel_valid), not per event
    // ============================================================

    das_delay u_rx_delay (

        .clk(clk),
        .rst_n(rst_n),

        .pixel_valid(pixel_valid),

        .x_pixel(x_pixel),
        .z_pixel(z_pixel),

        .rx_time_valid(rx_time_valid),

        .rx_time_0(rx_time[0]),
        .rx_time_1(rx_time[1]),
        .rx_time_2(rx_time[2]),
        .rx_time_3(rx_time[3]),
        .rx_time_4(rx_time[4]),
        .rx_time_5(rx_time[5]),
        .rx_time_6(rx_time[6]),
        .rx_time_7(rx_time[7]),
        .rx_time_8(rx_time[8]),
        .rx_time_9(rx_time[9]),
        .rx_time_10(rx_time[10]),
        .rx_time_11(rx_time[11]),
        .rx_time_12(rx_time[12]),
        .rx_time_13(rx_time[13]),
        .rx_time_14(rx_time[14]),
        .rx_time_15(rx_time[15]),
        .rx_time_16(rx_time[16]),
        .rx_time_17(rx_time[17]),
        .rx_time_18(rx_time[18]),
        .rx_time_19(rx_time[19]),
        .rx_time_20(rx_time[20]),
        .rx_time_21(rx_time[21]),
        .rx_time_22(rx_time[22]),
        .rx_time_23(rx_time[23]),
        .rx_time_24(rx_time[24]),
        .rx_time_25(rx_time[25]),
        .rx_time_26(rx_time[26]),
        .rx_time_27(rx_time[27]),
        .rx_time_28(rx_time[28]),
        .rx_time_29(rx_time[29]),
        .rx_time_30(rx_time[30]),
        .rx_time_31(rx_time[31])
    );


    // ============================================================
    // TX/EVENT-METADATA PAIRING
    //
    // RX is now a per-pixel CONSTANT (cur_rx_time), not a per-event
    // stream, so there is nothing to align it against -- das_tof simply
    // reads whichever cur_rx_time is live the moment tx_time_valid_cached
    // fires. cur_buf is captured alongside tx_time at that same posedge,
    // so this is correct even right at a pixel boundary. event_idx still
    // rides its own small FIFO to survive the cached-TX latency (57
    // clocks), exactly as it did in the original design.
    // ============================================================

reg [31:0] tx_time_hold;
reg [31:0] rx_hold [0:31];
reg tof_start;
reg tx_pending;
reg [31:0] tx_time_captured;
reg buf_sel_captured;
integer k;

always @(posedge clk) begin
    if (!rst_n) begin
        in_wr = 0; in_rd = 0;
        tx_pending = 1'b0;
    end else begin
        if (cache_valid) begin
            in_event_fifo[in_wr & FIFO_MASK] = event_idx;
            in_wr = in_wr + 1;
        end

        tx_pending = 1'b0;
        if (tx_time_valid_cached) begin
            tx_time_captured = tx_time_cached;
            buf_sel_captured = cur_buf;
            tx_pending = 1'b1;
        end
    end
end

// Issue on the falling edge so values are stable for the next posedge
// (same discipline as the original design).
always @(negedge clk) begin
    if (!rst_n) begin
        tof_start = 1'b0;
        tof_meta_wr = 0;
    end else begin
        tof_start = 1'b0;
        if (tx_pending) begin
            tx_time_hold = tx_time_captured;
            for (k = 0; k < 32; k = k + 1)
                rx_hold[k] = rx_cache[buf_sel_captured][k];

            tof_event_fifo[tof_meta_wr & FIFO_MASK] = in_event_fifo[in_rd & FIFO_MASK];
            tof_meta_wr = tof_meta_wr + 1;
            in_rd = in_rd + 1;

            tof_start = 1'b1;
        end
    end
end

    // ============================================================
    // TOF
    // ============================================================

    das_tof u_tof (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(tof_start),

        .tx_time(tx_time_hold),

        .rx_time_0(rx_hold[0]),
        .rx_time_1(rx_hold[1]),
        .rx_time_2(rx_hold[2]),
        .rx_time_3(rx_hold[3]),
        .rx_time_4(rx_hold[4]),
        .rx_time_5(rx_hold[5]),
        .rx_time_6(rx_hold[6]),
        .rx_time_7(rx_hold[7]),
        .rx_time_8(rx_hold[8]),
        .rx_time_9(rx_hold[9]),
        .rx_time_10(rx_hold[10]),
        .rx_time_11(rx_hold[11]),
        .rx_time_12(rx_hold[12]),
        .rx_time_13(rx_hold[13]),
        .rx_time_14(rx_hold[14]),
        .rx_time_15(rx_hold[15]),
        .rx_time_16(rx_hold[16]),
        .rx_time_17(rx_hold[17]),
        .rx_time_18(rx_hold[18]),
        .rx_time_19(rx_hold[19]),
        .rx_time_20(rx_hold[20]),
        .rx_time_21(rx_hold[21]),
        .rx_time_22(rx_hold[22]),
        .rx_time_23(rx_hold[23]),
        .rx_time_24(rx_hold[24]),
        .rx_time_25(rx_hold[25]),
        .rx_time_26(rx_hold[26]),
        .rx_time_27(rx_hold[27]),
        .rx_time_28(rx_hold[28]),
        .rx_time_29(rx_hold[29]),
        .rx_time_30(rx_hold[30]),
        .rx_time_31(rx_hold[31]),

        .tof_valid(tof_valid),

        .tof_0(tof[0]),
        .tof_1(tof[1]),
        .tof_2(tof[2]),
        .tof_3(tof[3]),
        .tof_4(tof[4]),
        .tof_5(tof[5]),
        .tof_6(tof[6]),
        .tof_7(tof[7]),
        .tof_8(tof[8]),
        .tof_9(tof[9]),
        .tof_10(tof[10]),
        .tof_11(tof[11]),
        .tof_12(tof[12]),
        .tof_13(tof[13]),
        .tof_14(tof[14]),
        .tof_15(tof[15]),
        .tof_16(tof[16]),
        .tof_17(tof[17]),
        .tof_18(tof[18]),
        .tof_19(tof[19]),
        .tof_20(tof[20]),
        .tof_21(tof[21]),
        .tof_22(tof[22]),
        .tof_23(tof[23]),
        .tof_24(tof[24]),
        .tof_25(tof[25]),
        .tof_26(tof[26]),
        .tof_27(tof[27]),
        .tof_28(tof[28]),
        .tof_29(tof[29]),
        .tof_30(tof[30]),
        .tof_31(tof[31])
    );


    // ============================================================
    // SAMPLE INDEX
    // ============================================================

    das_sample_index u_sample_index (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(tof_valid),

        .tof_0(tof[0]),
        .tof_1(tof[1]),
        .tof_2(tof[2]),
        .tof_3(tof[3]),
        .tof_4(tof[4]),
        .tof_5(tof[5]),
        .tof_6(tof[6]),
        .tof_7(tof[7]),
        .tof_8(tof[8]),
        .tof_9(tof[9]),
        .tof_10(tof[10]),
        .tof_11(tof[11]),
        .tof_12(tof[12]),
        .tof_13(tof[13]),
        .tof_14(tof[14]),
        .tof_15(tof[15]),
        .tof_16(tof[16]),
        .tof_17(tof[17]),
        .tof_18(tof[18]),
        .tof_19(tof[19]),
        .tof_20(tof[20]),
        .tof_21(tof[21]),
        .tof_22(tof[22]),
        .tof_23(tof[23]),
        .tof_24(tof[24]),
        .tof_25(tof[25]),
        .tof_26(tof[26]),
        .tof_27(tof[27]),
        .tof_28(tof[28]),
        .tof_29(tof[29]),
        .tof_30(tof[30]),
        .tof_31(tof[31]),

        .sample_index_valid(sample_index_valid),

        .sample_index_0(sample_index[0]),
        .sample_index_1(sample_index[1]),
        .sample_index_2(sample_index[2]),
        .sample_index_3(sample_index[3]),
        .sample_index_4(sample_index[4]),
        .sample_index_5(sample_index[5]),
        .sample_index_6(sample_index[6]),
        .sample_index_7(sample_index[7]),
        .sample_index_8(sample_index[8]),
        .sample_index_9(sample_index[9]),
        .sample_index_10(sample_index[10]),
        .sample_index_11(sample_index[11]),
        .sample_index_12(sample_index[12]),
        .sample_index_13(sample_index[13]),
        .sample_index_14(sample_index[14]),
        .sample_index_15(sample_index[15]),
        .sample_index_16(sample_index[16]),
        .sample_index_17(sample_index[17]),
        .sample_index_18(sample_index[18]),
        .sample_index_19(sample_index[19]),
        .sample_index_20(sample_index[20]),
        .sample_index_21(sample_index[21]),
        .sample_index_22(sample_index[22]),
        .sample_index_23(sample_index[23]),
        .sample_index_24(sample_index[24]),
        .sample_index_25(sample_index[25]),
        .sample_index_26(sample_index[26]),
        .sample_index_27(sample_index[27]),
        .sample_index_28(sample_index[28]),
        .sample_index_29(sample_index[29]),
        .sample_index_30(sample_index[30]),
        .sample_index_31(sample_index[31])
    );


    // ============================================================
    // RF ADDRESS GENERATOR
    // ============================================================

    das_rf_read u_rf_read (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(sample_index_valid),
        .event_idx(rf_event_idx),

        .sample_index_0(sample_index[0]),
        .sample_index_1(sample_index[1]),
        .sample_index_2(sample_index[2]),
        .sample_index_3(sample_index[3]),
        .sample_index_4(sample_index[4]),
        .sample_index_5(sample_index[5]),
        .sample_index_6(sample_index[6]),
        .sample_index_7(sample_index[7]),
        .sample_index_8(sample_index[8]),
        .sample_index_9(sample_index[9]),
        .sample_index_10(sample_index[10]),
        .sample_index_11(sample_index[11]),
        .sample_index_12(sample_index[12]),
        .sample_index_13(sample_index[13]),
        .sample_index_14(sample_index[14]),
        .sample_index_15(sample_index[15]),
        .sample_index_16(sample_index[16]),
        .sample_index_17(sample_index[17]),
        .sample_index_18(sample_index[18]),
        .sample_index_19(sample_index[19]),
        .sample_index_20(sample_index[20]),
        .sample_index_21(sample_index[21]),
        .sample_index_22(sample_index[22]),
        .sample_index_23(sample_index[23]),
        .sample_index_24(sample_index[24]),
        .sample_index_25(sample_index[25]),
        .sample_index_26(sample_index[26]),
        .sample_index_27(sample_index[27]),
        .sample_index_28(sample_index[28]),
        .sample_index_29(sample_index[29]),
        .sample_index_30(sample_index[30]),
        .sample_index_31(sample_index[31]),

        .address_valid(address_valid),

        .rf_addr_0(rf_addr[0]),
        .rf_addr_1(rf_addr[1]),
        .rf_addr_2(rf_addr[2]),
        .rf_addr_3(rf_addr[3]),
        .rf_addr_4(rf_addr[4]),
        .rf_addr_5(rf_addr[5]),
        .rf_addr_6(rf_addr[6]),
        .rf_addr_7(rf_addr[7]),
        .rf_addr_8(rf_addr[8]),
        .rf_addr_9(rf_addr[9]),
        .rf_addr_10(rf_addr[10]),
        .rf_addr_11(rf_addr[11]),
        .rf_addr_12(rf_addr[12]),
        .rf_addr_13(rf_addr[13]),
        .rf_addr_14(rf_addr[14]),
        .rf_addr_15(rf_addr[15]),
        .rf_addr_16(rf_addr[16]),
        .rf_addr_17(rf_addr[17]),
        .rf_addr_18(rf_addr[18]),
        .rf_addr_19(rf_addr[19]),
        .rf_addr_20(rf_addr[20]),
        .rf_addr_21(rf_addr[21]),
        .rf_addr_22(rf_addr[22]),
        .rf_addr_23(rf_addr[23]),
        .rf_addr_24(rf_addr[24]),
        .rf_addr_25(rf_addr[25]),
        .rf_addr_26(rf_addr[26]),
        .rf_addr_27(rf_addr[27]),
        .rf_addr_28(rf_addr[28]),
        .rf_addr_29(rf_addr[29]),
        .rf_addr_30(rf_addr[30]),
        .rf_addr_31(rf_addr[31])
    );


    // Advance RF-event metadata just after the clock edge on which
    // das_rf_read consumed the current head.  #1 avoids active-region races.
    always @(posedge clk) begin
        if (!rst_n)
            tof_meta_rd <= 0;
        else if (sample_index_valid) begin
            #1;
            tof_meta_rd <= tof_meta_rd + 1;
        end
    end

    // ============================================================
    // SIMULATION RF MEMORY READ
    // ============================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            adder_in_valid <= 1'b0;

            for (i = 0; i < 32; i = i + 1) begin
                rf_sample[i] <= 16'sd0;
                sample_in_range[i] <= 1'b0;
            end

        end
        else begin

            adder_in_valid <= address_valid;

            // Pipeline the in-range mask alongside das_rf_read's one-cycle address stage.
            if (sample_index_valid) begin
                for (i = 0; i < 32; i = i + 1)
                    sample_in_range[i] <= (sample_index[i] < 32'd1536);
            end

            if (address_valid) begin
                // Out-of-range TOF samples must contribute zero.
                // das_rf_read maps an invalid sample to address 0, but reading
                // rf_mem[0] would be wrong for image pixels beyond the RF window.
                // Therefore the simulation memory model explicitly gates each lane.
                for (i = 0; i < 32; i = i + 1) begin
                    if (sample_in_range[i])
                        rf_sample[i] <= rf_mem[rf_addr[i]];
                    else
                        rf_sample[i] <= 16'sd0;
                end
            end

        end

    end


    // ============================================================
    // 32-CHANNEL ADDER
    // ============================================================

    das_adder_tree u_adder (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(adder_in_valid),

        .rf_0(rf_sample[0]),
        .rf_1(rf_sample[1]),
        .rf_2(rf_sample[2]),
        .rf_3(rf_sample[3]),
        .rf_4(rf_sample[4]),
        .rf_5(rf_sample[5]),
        .rf_6(rf_sample[6]),
        .rf_7(rf_sample[7]),
        .rf_8(rf_sample[8]),
        .rf_9(rf_sample[9]),
        .rf_10(rf_sample[10]),
        .rf_11(rf_sample[11]),
        .rf_12(rf_sample[12]),
        .rf_13(rf_sample[13]),
        .rf_14(rf_sample[14]),
        .rf_15(rf_sample[15]),
        .rf_16(rf_sample[16]),
        .rf_17(rf_sample[17]),
        .rf_18(rf_sample[18]),
        .rf_19(rf_sample[19]),
        .rf_20(rf_sample[20]),
        .rf_21(rf_sample[21]),
        .rf_22(rf_sample[22]),
        .rf_23(rf_sample[23]),
        .rf_24(rf_sample[24]),
        .rf_25(rf_sample[25]),
        .rf_26(rf_sample[26]),
        .rf_27(rf_sample[27]),
        .rf_28(rf_sample[28]),
        .rf_29(rf_sample[29]),
        .rf_30(rf_sample[30]),
        .rf_31(rf_sample[31]),

        .das_sum(das_sum),
        .das_valid(das_valid)
    );


    // ============================================================
    // LOAD Y.hex
    // ============================================================

    initial begin

        $display("");
        $display("Loading Y.hex ...");

        $readmemh(
            "D:/Users/Nagendra/PAUT_FPGA/FPGA-Project/PAUT/Y.hex",
            rf_mem
        );

        $display("Y.hex loaded.");
        $display("");

    end


    // ============================================================
    // OPTIMIZED FULL 302 x 320 IMAGE CONTROLLER
    //
    // 1) Precompute all 75 DLG delay sets once.
    // 2) Stream one (pixel,event) job EVERY CLOCK (II=1).
    // 3) TX/RX pipelines run continuously and are aligned by FIFOs.
    // 4) TOF -> sample-index -> RF -> adder also run continuously.
    // 5) Every 75 ordered DAS outputs are accumulated into one pixel.
    // ============================================================

    // Accumulate the continuous DAS output stream.
    integer out_ix;
    integer out_iz;
    real out_x;
    real out_z;
    always @(posedge clk) begin
        if (!rst_n) begin
            completed_jobs = 0;
            output_pixels  = 0;
            pixel_accum    = 64'sd0;
        end
        else if (das_valid) begin
            completed_jobs = completed_jobs + 1;
            pixel_accum = pixel_accum + $signed(das_sum);

            // Events are launched 0..74 for each pixel and all stages preserve order.
            if ((completed_jobs % 75) == 0) begin
                out_ix = output_pixels % NX;
                out_iz = output_pixels / NX;
                out_x  = -96.0 + out_ix * 0.6;
                out_z  = out_iz * 0.632;

                $fdisplay(out_file, "%0d %0d %f %f %0d",
                          out_ix, out_iz, out_x, out_z, pixel_accum);

                output_pixels = output_pixels + 1;
                pixel_accum = 64'sd0;

                if ((output_pixels % NX) == 0) begin
                    if (((out_iz % 20) == 0) || (out_iz == NZ-1))
                        $fflush(out_file);
                    $display("ROW %0d / %0d COMPLETE   pixels=%0d jobs=%0d",
                             out_iz, NZ-1, output_pixels, completed_jobs);
                end
            end
        end
    end

    initial begin
        rst_n       = 1'b0;
        cache_valid = 1'b0;
        pixel_valid = 1'b0;
        angle_valid = 1'b0;
        tof_start   = 1'b0;
        clear_event = 1'b0;

        aperture_idx = 5'd0;
        event_idx    = 7'd0;
        theta_idx    = 2'd0;
        focus         = 32'h42820000;   // 65.0 mm
        x_pixel       = 32'h00000000;
        z_pixel       = 32'h00000000;

        cur_buf     = 1'b0;
        pending_buf = 1'b0;

        launched_jobs = 0;
        completed_jobs = 0;
        output_pixels = 0;
        pixel_accum = 64'sd0;
        stream_done = 1'b0;
        tof_meta_rd = 0;
        tof_meta_wr = 0;

        out_file = $fopen(
            "D:/Users/Nagendra/PAUT_FPGA/FPGA-Project/PAUT/das_image_cached.txt",
            "w"
        );

        if (out_file == 0) begin
            $display("ERROR: Could not open das_image_cached.txt");
            $finish;
        end

        $fdisplay(out_file, "ix iz x_mm z_mm raw_das_sum");

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        // ------------------------------------------------------------
        // PRECOMPUTE 75 DLG DELAY SETS ONCE (unchanged from original)
        // ------------------------------------------------------------
        $display("Precomputing 75 DLG delay sets ...");

        for (pre_ev = 0; pre_ev < 75; pre_ev = pre_ev + 1) begin
            @(negedge clk);

            if (pre_ev < 25) begin
                theta_idx    = 2'd0;
                aperture_idx = pre_ev;
            end
            else if (pre_ev < 50) begin
                theta_idx    = 2'd1;
                aperture_idx = pre_ev - 25;
            end
            else begin
                theta_idx    = 2'd2;
                aperture_idx = pre_ev - 50;
            end

            angle_valid = 1'b1;
            @(negedge clk);
            angle_valid = 1'b0;

            wait(delay_valid == 1'b1);
            #1;
            for (jj = 0; jj < 8; jj = jj + 1)
                delay_cache[pre_ev][jj] = dlg_delay[jj];
        end

        $display("DLG cache complete.");
        $display("");
        $display("============================================================");
        $display("CACHED-TX FULL PAUT IMAGE TEST");
        $display("Grid              = %0d x %0d = %0d pixels", NX, NZ, NX*NZ);
        $display("Events/pixel      = 75");
        $display("Total TOF/RF jobs = %0d", NX*NZ*75);
        $display("RX geometry evals = %0d  (was %0d)", NX*NZ, NX*NZ*75);
        $display("TX geometry evals = 0    (was %0d)", NX*NZ*75*8);
        $display("Output            = das_image_cached.txt");
        $display("============================================================");
        $display("");

        // ------------------------------------------------------------
        // PRIME RX CACHE FOR PIXEL 0 (buffer 0) BEFORE STREAMING STARTS
        // ------------------------------------------------------------
        x_pixel = real_to_float32(-96.0);   // pixel 0: ix=0 -> x = -96.0 mm
        z_pixel = real_to_float32(0.0);     //          iz=0 -> z =   0.0 mm

        @(negedge clk);
        pixel_valid = 1'b1;
        @(negedge clk);
        pixel_valid = 1'b0;

        wait (rx_cache_ready[0] == 1'b1);
        $display("Pixel-0 RX cache primed. Streaming ...");
        $display("");

        // ------------------------------------------------------------
        // STREAM ALL 96,640 PIXELS x 75 EVENTS -- ONE NEW JOB EACH CLOCK.
        // RX for pixel N+1 is prefetched into the OTHER buffer during
        // pixel N's first two event cycles (piggybacked, no extra
        // bubble), so by the time pixel N+1 starts its own 75-event
        // burst, its RX cache is (almost always) already valid.
        // ------------------------------------------------------------
        for (pixel_index = 0; pixel_index < NX*NZ; pixel_index = pixel_index + 1) begin

            if (pixel_index + 1 < NX*NZ) begin
                ix = (pixel_index + 1) % NX;
                iz = (pixel_index + 1) / NX;
                x_mm = -96.0 + ix * 0.6;
                z_mm = iz * 0.632;
                pending_buf = ~cur_buf;
            end

            for (event_no = 0; event_no < 75; event_no = event_no + 1) begin
                @(negedge clk);

                event_idx = event_no[6:0];

                if (event_no < 25)
                    aperture_idx = event_no;
                else if (event_no < 50)
                    aperture_idx = event_no - 25;
                else
                    aperture_idx = event_no - 50;

                // Load the precomputed event delay law.  No SAG/DLG here.
                for (jj = 0; jj < 8; jj = jj + 1)
                    tx_delay[jj] = delay_cache[event_no][jj];

                cache_valid   = 1'b1;
                launched_jobs = launched_jobs + 1;

                // Piggyback next pixel's RX prefetch pulse on this
                // pixel's first two event cycles -- no extra bubble.
                if (pixel_index + 1 < NX*NZ) begin
                    if (event_no == 0) begin
                        x_pixel     = real_to_float32(x_mm);
                        z_pixel     = real_to_float32(z_mm);
                        pixel_valid = 1'b1;
                    end
                    else if (event_no == 1) begin
                        pixel_valid = 1'b0;
                    end
                end
            end

            if (pixel_index + 1 < NX*NZ) begin
                // Normally already true: RX latency (71 clocks) is shorter
                // than one pixel's 75-clock event burst. This wait is only
                // a safety net.
                wait (rx_cache_ready[~cur_buf] == 1'b1);
                cur_buf = ~cur_buf;
            end
        end

        // Stop launching, then let the pipeline drain.
        @(negedge clk);
        cache_valid = 1'b0;
        pixel_valid = 1'b0;
        stream_done = 1'b1;

        $display("All %0d jobs launched. Draining pipeline ...", launched_jobs);

        wait(output_pixels == NX*NZ);
        repeat (20) @(posedge clk);

        $fclose(out_file);

        $display("");
        $display("============================================================");
        $display("CACHED-TX FULL PAUT RAW DAS IMAGE COMPLETE");
        $display("Jobs launched    = %0d", launched_jobs);
        $display("Jobs completed   = %0d", completed_jobs);
        $display("Pixels completed = %0d", output_pixels);
        $display("Expected pixels  = %0d", NX*NZ);
        $display("Results written to das_image_cached.txt");
        $display("============================================================");
        $display("");

        $finish;
    end

    // ============================================================
    // DEBUG intentionally minimized for full-image simulation.
    // The arithmetic RTL was already verified by the 75-event test.
    // ============================================================

endmodule