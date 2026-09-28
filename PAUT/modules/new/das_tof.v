`timescale 1ns / 1ps

// ============================================================================
// DAS TOTAL TIME-OF-FLIGHT
//
// For each receive element:
//
//      TOF[j] = TX_TIME + RX_TIME[j]
//
// Inputs:
//      tx_time      : transmit arrival time at pixel [us]
//      rx_time[j]   : pixel -> RX element propagation time [us]
//
// Output:
//      tof[j]       : complete TX + RX time-of-flight [us]
//
// Architecture:
//      32 floating-point adders in parallel
//      Fully pipelined
//      Target II = 1
//
// IMPORTANT:
//      tx_time and rx_time[0:31] must belong to the SAME pixel/event
//      when in_valid is asserted.
// ============================================================================

module das_tof (

    input  wire        clk,
    input  wire        rst_n,

    input  wire        in_valid,

    input  wire [31:0] tx_time,

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

    output wire        tof_valid,

    output wire [31:0] tof_0,
    output wire [31:0] tof_1,
    output wire [31:0] tof_2,
    output wire [31:0] tof_3,
    output wire [31:0] tof_4,
    output wire [31:0] tof_5,
    output wire [31:0] tof_6,
    output wire [31:0] tof_7,
    output wire [31:0] tof_8,
    output wire [31:0] tof_9,
    output wire [31:0] tof_10,
    output wire [31:0] tof_11,
    output wire [31:0] tof_12,
    output wire [31:0] tof_13,
    output wire [31:0] tof_14,
    output wire [31:0] tof_15,
    output wire [31:0] tof_16,
    output wire [31:0] tof_17,
    output wire [31:0] tof_18,
    output wire [31:0] tof_19,
    output wire [31:0] tof_20,
    output wire [31:0] tof_21,
    output wire [31:0] tof_22,
    output wire [31:0] tof_23,
    output wire [31:0] tof_24,
    output wire [31:0] tof_25,
    output wire [31:0] tof_26,
    output wire [31:0] tof_27,
    output wire [31:0] tof_28,
    output wire [31:0] tof_29,
    output wire [31:0] tof_30,
    output wire [31:0] tof_31
);


    // ========================================================================
    // Convert ports into internal arrays
    // ========================================================================

    wire [31:0] rx_time [0:31];
    wire [31:0] tof     [0:31];

    wire tof_lane_valid [0:31];


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
    // 32 PARALLEL TOF ADDERS
    //
    // TOF[j] = TX_TIME + RX_TIME[j]
    //
    // floating_point_add latency = 12 clocks
    // cycles per operation = 1
    // ========================================================================

    genvar g;

    generate

        for (g = 0; g < 32; g = g + 1) begin : TOF_ADDERS

            floating_point_add add_tof (

                .aclk                 (clk),

                .s_axis_a_tvalid      (in_valid),
                .s_axis_a_tdata       (tx_time),

                .s_axis_b_tvalid      (in_valid),
                .s_axis_b_tdata       (rx_time[g]),

                .m_axis_result_tvalid (tof_lane_valid[g]),
                .m_axis_result_tdata  (tof[g])

            );

        end

    endgenerate


    // ========================================================================
    // Output valid
    //
    // All 32 lanes should become valid together.
    // ========================================================================

    assign tof_valid =
        tof_lane_valid[0]  &
        tof_lane_valid[1]  &
        tof_lane_valid[2]  &
        tof_lane_valid[3]  &
        tof_lane_valid[4]  &
        tof_lane_valid[5]  &
        tof_lane_valid[6]  &
        tof_lane_valid[7]  &
        tof_lane_valid[8]  &
        tof_lane_valid[9]  &
        tof_lane_valid[10] &
        tof_lane_valid[11] &
        tof_lane_valid[12] &
        tof_lane_valid[13] &
        tof_lane_valid[14] &
        tof_lane_valid[15] &
        tof_lane_valid[16] &
        tof_lane_valid[17] &
        tof_lane_valid[18] &
        tof_lane_valid[19] &
        tof_lane_valid[20] &
        tof_lane_valid[21] &
        tof_lane_valid[22] &
        tof_lane_valid[23] &
        tof_lane_valid[24] &
        tof_lane_valid[25] &
        tof_lane_valid[26] &
        tof_lane_valid[27] &
        tof_lane_valid[28] &
        tof_lane_valid[29] &
        tof_lane_valid[30] &
        tof_lane_valid[31];


    // ========================================================================
    // Output mapping
    // ========================================================================

    assign tof_0  = tof[0];
    assign tof_1  = tof[1];
    assign tof_2  = tof[2];
    assign tof_3  = tof[3];
    assign tof_4  = tof[4];
    assign tof_5  = tof[5];
    assign tof_6  = tof[6];
    assign tof_7  = tof[7];
    assign tof_8  = tof[8];
    assign tof_9  = tof[9];
    assign tof_10 = tof[10];
    assign tof_11 = tof[11];
    assign tof_12 = tof[12];
    assign tof_13 = tof[13];
    assign tof_14 = tof[14];
    assign tof_15 = tof[15];
    assign tof_16 = tof[16];
    assign tof_17 = tof[17];
    assign tof_18 = tof[18];
    assign tof_19 = tof[19];
    assign tof_20 = tof[20];
    assign tof_21 = tof[21];
    assign tof_22 = tof[22];
    assign tof_23 = tof[23];
    assign tof_24 = tof[24];
    assign tof_25 = tof[25];
    assign tof_26 = tof[26];
    assign tof_27 = tof[27];
    assign tof_28 = tof[28];
    assign tof_29 = tof[29];
    assign tof_30 = tof[30];
    assign tof_31 = tof[31];


endmodule