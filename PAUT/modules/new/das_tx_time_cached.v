`timescale 1ns / 1ps

// ============================================================================
// DAS TX TIME -- CACHED (no distance/SQRT geometry)
//
// TX propagation for an active TX element is the SAME calculation as RX
// propagation for that same physical element:
//
//   dx      = x_pixel - x_element
//   distance = sqrt(dx^2 + z_pixel^2)
//   prop_time = distance / c
//
// das_delay already computes this for all 32 elements, once per pixel, as
// rx_time_0..rx_time_31 -- using the SAME element_position LUT and the SAME
// INV_C constant (0x3E22067B) as das_tx_time. So for aperture window
// [aperture_idx .. aperture_idx+7]:
//
//   original prop_time[g]  ==  rx_time[aperture_idx + g]   (bit-exact)
//
// This module skips the entire sub -> mult -> add -> sqrt -> mult chain (71
// clocks x 8 lanes of Xilinx floating-point IP per event) and just slices 8
// already-computed RX values out of the per-pixel cache, adds the DLG TX
// delay, and runs them through the IDENTICAL adder tree as the original
// das_tx_time, in the same order, so the final tx_time is bit-for-bit the
// same as the original module would have produced.
//
// CALLER CONTRACT:
//   rx_time_0..31 must be the das_delay output for the CURRENT pixel
//   (x_pixel, z_pixel), held stable for the entire 75-event burst of that
//   pixel. Do not change rx_time_* mid-burst.
//
// Units:
//   tx_delay : us
//   tx_time  : us
//
// Latency:
//   add_tx_delay   = 12
//   add_01/23/45/67 = 12  (level 1)
//   add_0123/4567   = 12  (level 2)
//   add_all         = 12  (level 3)
//   mult_one_eighth =  9
//   Total           = 57  (vs 128 in the original -- and zero SQRT/mult/sub
//                          geometry cores per event instead of 8 of each)
// ============================================================================

module das_tx_time_cached (

    input  wire        clk,
    input  wire        rst_n,

    input  wire        in_valid,

    input  wire [4:0]  aperture_idx,

    // Per-pixel RX cache from das_delay -- held constant for all 75 events
    // of the current pixel.
    input  wire [31:0] rx_time_0,
    input  wire [31:0] rx_time_1,
    input  wire [31:0] rx_time_2,
    input  wire [31:0] rx_time_3,
    input  wire [31:0] rx_time_4,
    input  wire [31:0] rx_time_5,
    input  wire [31:0] rx_time_6,
    input  wire [31:0] rx_time_7,
    input  wire [31:0] rx_time_8,
    input  wire [31:0] rx_time_9,
    input  wire [31:0] rx_time_10,
    input  wire [31:0] rx_time_11,
    input  wire [31:0] rx_time_12,
    input  wire [31:0] rx_time_13,
    input  wire [31:0] rx_time_14,
    input  wire [31:0] rx_time_15,
    input  wire [31:0] rx_time_16,
    input  wire [31:0] rx_time_17,
    input  wire [31:0] rx_time_18,
    input  wire [31:0] rx_time_19,
    input  wire [31:0] rx_time_20,
    input  wire [31:0] rx_time_21,
    input  wire [31:0] rx_time_22,
    input  wire [31:0] rx_time_23,
    input  wire [31:0] rx_time_24,
    input  wire [31:0] rx_time_25,
    input  wire [31:0] rx_time_26,
    input  wire [31:0] rx_time_27,
    input  wire [31:0] rx_time_28,
    input  wire [31:0] rx_time_29,
    input  wire [31:0] rx_time_30,
    input  wire [31:0] rx_time_31,

    // DLG delays in microseconds
    input  wire [31:0] tx_delay_0,
    input  wire [31:0] tx_delay_1,
    input  wire [31:0] tx_delay_2,
    input  wire [31:0] tx_delay_3,
    input  wire [31:0] tx_delay_4,
    input  wire [31:0] tx_delay_5,
    input  wire [31:0] tx_delay_6,
    input  wire [31:0] tx_delay_7,

    output wire        tx_time_valid,
    output wire [31:0] tx_time
);

    // ========================================================================
    // Constants (must match das_tx_time.v exactly)
    // ========================================================================

    // 1 / 8 = 0.125
    localparam [31:0] ONE_EIGHTH = 32'h3E000000;


    // ========================================================================
    // Cached RX time array
    // ========================================================================

    wire [31:0] rx_time [0:31];

    assign rx_time[0]  = rx_time_0;
    assign rx_time[1]  = rx_time_1;
    assign rx_time[2]  = rx_time_2;
    assign rx_time[3]  = rx_time_3;
    assign rx_time[4]  = rx_time_4;
    assign rx_time[5]  = rx_time_5;
    assign rx_time[6]  = rx_time_6;
    assign rx_time[7]  = rx_time_7;
    assign rx_time[8]  = rx_time_8;
    assign rx_time[9]  = rx_time_9;
    assign rx_time[10] = rx_time_10;
    assign rx_time[11] = rx_time_11;
    assign rx_time[12] = rx_time_12;
    assign rx_time[13] = rx_time_13;
    assign rx_time[14] = rx_time_14;
    assign rx_time[15] = rx_time_15;
    assign rx_time[16] = rx_time_16;
    assign rx_time[17] = rx_time_17;
    assign rx_time[18] = rx_time_18;
    assign rx_time[19] = rx_time_19;
    assign rx_time[20] = rx_time_20;
    assign rx_time[21] = rx_time_21;
    assign rx_time[22] = rx_time_22;
    assign rx_time[23] = rx_time_23;
    assign rx_time[24] = rx_time_24;
    assign rx_time[25] = rx_time_25;
    assign rx_time[26] = rx_time_26;
    assign rx_time[27] = rx_time_27;
    assign rx_time[28] = rx_time_28;
    assign rx_time[29] = rx_time_29;
    assign rx_time[30] = rx_time_30;
    assign rx_time[31] = rx_time_31;


    // ========================================================================
    // TX delay input array
    // ========================================================================

    wire [31:0] tx_delay [0:7];

    assign tx_delay[0] = tx_delay_0;
    assign tx_delay[1] = tx_delay_1;
    assign tx_delay[2] = tx_delay_2;
    assign tx_delay[3] = tx_delay_3;
    assign tx_delay[4] = tx_delay_4;
    assign tx_delay[5] = tx_delay_5;
    assign tx_delay[6] = tx_delay_6;
    assign tx_delay[7] = tx_delay_7;


    // ========================================================================
    // 8 lanes: tau_g = rx_time[aperture_idx + g] + tx_delay_g
    //
    // element_index = aperture_idx + g, exactly mirroring das_tx_time.v's
    // "assign element_index = aperture_idx + g;" -- same sliding 8-of-32
    // window, apertures 0..24 => index range 0..31.
    // ========================================================================

    wire [31:0] tau [0:7];
    wire        tau_valid [0:7];

    genvar g;

    generate
        for (g = 0; g < 8; g = g + 1) begin : TX_LANES_CACHED

            wire [4:0]  element_index;
            wire [31:0] selected_rx;

            assign element_index = aperture_idx + g;
            assign selected_rx   = rx_time[element_index];

            // ================================================================
            // tau = cached RX propagation time + DLG firing delay
            //
            // Same core, same latency (12) as the original add_tx_delay --
            // but no 71-cycle alignment pipe needed, since selected_rx and
            // tx_delay are both already valid the moment in_valid asserts.
            // ================================================================

            floating_point_add add_tx_delay_cached (

                .aclk                 (clk),

                .s_axis_a_tvalid      (in_valid),
                .s_axis_a_tdata       (selected_rx),

                .s_axis_b_tvalid      (in_valid),
                .s_axis_b_tdata       (tx_delay[g]),

                .m_axis_result_tvalid (tau_valid[g]),
                .m_axis_result_tdata  (tau[g])

            );

        end
    endgenerate


    // ========================================================================
    // All 8 TX lanes valid
    // ========================================================================

    wire tau_all_valid;

    assign tau_all_valid =
        tau_valid[0] &
        tau_valid[1] &
        tau_valid[2] &
        tau_valid[3] &
        tau_valid[4] &
        tau_valid[5] &
        tau_valid[6] &
        tau_valid[7];


    // ========================================================================
    // PIPELINED ADDER TREE -- IDENTICAL structure/order to das_tx_time.v
    //
    // Level 1: 8 -> 4
    // ========================================================================

    wire [31:0] sum01;
    wire [31:0] sum23;
    wire [31:0] sum45;
    wire [31:0] sum67;

    wire v01;
    wire v23;
    wire v45;
    wire v67;


    floating_point_add add_01 (

        .aclk                 (clk),

        .s_axis_a_tvalid      (tau_all_valid),
        .s_axis_a_tdata       (tau[0]),

        .s_axis_b_tvalid      (tau_all_valid),
        .s_axis_b_tdata       (tau[1]),

        .m_axis_result_tvalid (v01),
        .m_axis_result_tdata  (sum01)

    );


    floating_point_add add_23 (

        .aclk                 (clk),

        .s_axis_a_tvalid      (tau_all_valid),
        .s_axis_a_tdata       (tau[2]),

        .s_axis_b_tvalid      (tau_all_valid),
        .s_axis_b_tdata       (tau[3]),

        .m_axis_result_tvalid (v23),
        .m_axis_result_tdata  (sum23)

    );


    floating_point_add add_45 (

        .aclk                 (clk),

        .s_axis_a_tvalid      (tau_all_valid),
        .s_axis_a_tdata       (tau[4]),

        .s_axis_b_tvalid      (tau_all_valid),
        .s_axis_b_tdata       (tau[5]),

        .m_axis_result_tvalid (v45),
        .m_axis_result_tdata  (sum45)

    );


    floating_point_add add_67 (

        .aclk                 (clk),

        .s_axis_a_tvalid      (tau_all_valid),
        .s_axis_a_tdata       (tau[6]),

        .s_axis_b_tvalid      (tau_all_valid),
        .s_axis_b_tdata       (tau[7]),

        .m_axis_result_tvalid (v67),
        .m_axis_result_tdata  (sum67)

    );


    // ========================================================================
    // Level 2: 4 -> 2
    // ========================================================================

    wire [31:0] sum0123;
    wire [31:0] sum4567;

    wire v0123;
    wire v4567;

    wire level2_valid;

    assign level2_valid =
        v01 & v23 & v45 & v67;


    floating_point_add add_0123 (

        .aclk                 (clk),

        .s_axis_a_tvalid      (level2_valid),
        .s_axis_a_tdata       (sum01),

        .s_axis_b_tvalid      (level2_valid),
        .s_axis_b_tdata       (sum23),

        .m_axis_result_tvalid (v0123),
        .m_axis_result_tdata  (sum0123)

    );


    floating_point_add add_4567 (

        .aclk                 (clk),

        .s_axis_a_tvalid      (level2_valid),
        .s_axis_a_tdata       (sum45),

        .s_axis_b_tvalid      (level2_valid),
        .s_axis_b_tdata       (sum67),

        .m_axis_result_tvalid (v4567),
        .m_axis_result_tdata  (sum4567)

    );


    // ========================================================================
    // Level 3: 2 -> 1
    // ========================================================================

    wire [31:0] sum_all;
    wire        sum_all_valid;

    wire level3_valid;

    assign level3_valid =
        v0123 & v4567;


    floating_point_add add_all (

        .aclk                 (clk),

        .s_axis_a_tvalid      (level3_valid),
        .s_axis_a_tdata       (sum0123),

        .s_axis_b_tvalid      (level3_valid),
        .s_axis_b_tdata       (sum4567),

        .m_axis_result_tvalid (sum_all_valid),
        .m_axis_result_tdata  (sum_all)

    );


    // ========================================================================
    // Divide by 8 -- identical to original
    // ========================================================================

    floating_point_mult mult_one_eighth (

        .aclk                 (clk),

        .s_axis_a_tvalid      (sum_all_valid),
        .s_axis_a_tdata       (sum_all),

        .s_axis_b_tvalid      (sum_all_valid),
        .s_axis_b_tdata       (ONE_EIGHTH),

        .m_axis_result_tvalid (tx_time_valid),
        .m_axis_result_tdata  (tx_time)

    );

endmodule
