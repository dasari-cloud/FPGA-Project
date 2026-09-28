`timescale 1ns / 1ps

// ============================================================================
// DAS SAMPLE INDEX GENERATOR
//
// Standard DAS - NO interpolation / NO upsampling
//
//      sample_position[j] = TOF[j] * Fs
//
// Fs = 40 MHz
// TOF is in microseconds
//
// Therefore:
//
//      samples/us = 40
//
// Architecture:
//      32 parallel multipliers
//      32 parallel Float -> Fixed converters
//
// Target:
//      II = 1
// ============================================================================

module das_sample_index (

    input  wire        clk,
    input  wire        rst_n,

    input  wire        in_valid,

    input  wire [31:0] tof_0,
    input  wire [31:0] tof_1,
    input  wire [31:0] tof_2,
    input  wire [31:0] tof_3,
    input  wire [31:0] tof_4,
    input  wire [31:0] tof_5,
    input  wire [31:0] tof_6,
    input  wire [31:0] tof_7,
    input  wire [31:0] tof_8,
    input  wire [31:0] tof_9,
    input  wire [31:0] tof_10,
    input  wire [31:0] tof_11,
    input  wire [31:0] tof_12,
    input  wire [31:0] tof_13,
    input  wire [31:0] tof_14,
    input  wire [31:0] tof_15,
    input  wire [31:0] tof_16,
    input  wire [31:0] tof_17,
    input  wire [31:0] tof_18,
    input  wire [31:0] tof_19,
    input  wire [31:0] tof_20,
    input  wire [31:0] tof_21,
    input  wire [31:0] tof_22,
    input  wire [31:0] tof_23,
    input  wire [31:0] tof_24,
    input  wire [31:0] tof_25,
    input  wire [31:0] tof_26,
    input  wire [31:0] tof_27,
    input  wire [31:0] tof_28,
    input  wire [31:0] tof_29,
    input  wire [31:0] tof_30,
    input  wire [31:0] tof_31,

    output wire        sample_index_valid,

    output wire [31:0] sample_index_0,
    output wire [31:0] sample_index_1,
    output wire [31:0] sample_index_2,
    output wire [31:0] sample_index_3,
    output wire [31:0] sample_index_4,
    output wire [31:0] sample_index_5,
    output wire [31:0] sample_index_6,
    output wire [31:0] sample_index_7,
    output wire [31:0] sample_index_8,
    output wire [31:0] sample_index_9,
    output wire [31:0] sample_index_10,
    output wire [31:0] sample_index_11,
    output wire [31:0] sample_index_12,
    output wire [31:0] sample_index_13,
    output wire [31:0] sample_index_14,
    output wire [31:0] sample_index_15,
    output wire [31:0] sample_index_16,
    output wire [31:0] sample_index_17,
    output wire [31:0] sample_index_18,
    output wire [31:0] sample_index_19,
    output wire [31:0] sample_index_20,
    output wire [31:0] sample_index_21,
    output wire [31:0] sample_index_22,
    output wire [31:0] sample_index_23,
    output wire [31:0] sample_index_24,
    output wire [31:0] sample_index_25,
    output wire [31:0] sample_index_26,
    output wire [31:0] sample_index_27,
    output wire [31:0] sample_index_28,
    output wire [31:0] sample_index_29,
    output wire [31:0] sample_index_30,
    output wire [31:0] sample_index_31
);

    // 40.0 IEEE-754 single precision
    localparam [31:0] FS = 32'h42200000;

    wire [31:0] tof [0:31];

    wire [31:0] sample_position [0:31];
    wire        sample_position_valid [0:31];

    wire [31:0] sample_index [0:31];
    wire        index_valid [0:31];


    // ============================================================
    // Input mapping
    // ============================================================

    assign tof[0]  = tof_0;
    assign tof[1]  = tof_1;
    assign tof[2]  = tof_2;
    assign tof[3]  = tof_3;
    assign tof[4]  = tof_4;
    assign tof[5]  = tof_5;
    assign tof[6]  = tof_6;
    assign tof[7]  = tof_7;
    assign tof[8]  = tof_8;
    assign tof[9]  = tof_9;
    assign tof[10] = tof_10;
    assign tof[11] = tof_11;
    assign tof[12] = tof_12;
    assign tof[13] = tof_13;
    assign tof[14] = tof_14;
    assign tof[15] = tof_15;
    assign tof[16] = tof_16;
    assign tof[17] = tof_17;
    assign tof[18] = tof_18;
    assign tof[19] = tof_19;
    assign tof[20] = tof_20;
    assign tof[21] = tof_21;
    assign tof[22] = tof_22;
    assign tof[23] = tof_23;
    assign tof[24] = tof_24;
    assign tof[25] = tof_25;
    assign tof[26] = tof_26;
    assign tof[27] = tof_27;
    assign tof[28] = tof_28;
    assign tof[29] = tof_29;
    assign tof[30] = tof_30;
    assign tof[31] = tof_31;


    // ============================================================
    // 32 parallel lanes
    // ============================================================

    genvar g;

    generate

        for (g = 0; g < 32; g = g + 1) begin : SAMPLE_INDEX_LANES

            // ----------------------------------------------------
            // Stage 1
            //
            // sample_position = TOF * 40
            // ----------------------------------------------------

            floating_point_mult mult_fs (

                .aclk                 (clk),

                .s_axis_a_tvalid      (in_valid),
                .s_axis_a_tdata       (tof[g]),

                .s_axis_b_tvalid      (in_valid),
                .s_axis_b_tdata       (FS),

                .m_axis_result_tvalid (sample_position_valid[g]),
                .m_axis_result_tdata  (sample_position[g])

            );


            // ----------------------------------------------------
            // Stage 2
            //
            // Float -> integer sample index
            //
            // Configure this IP for rounding to nearest.
            // ----------------------------------------------------

            floating_point_to_fixed fp_to_index (
                .aclk(clk),
            
                .s_axis_a_tvalid(sample_position_valid[g]),
                .s_axis_a_tdata(sample_position[g]),
            
                .m_axis_result_tvalid(index_valid[g]),
                .m_axis_result_tdata(sample_index[g])
            );

        end

    endgenerate


    // ============================================================
    // All 32 indices valid simultaneously
    // ============================================================

    assign sample_index_valid =
        index_valid[0]  &
        index_valid[1]  &
        index_valid[2]  &
        index_valid[3]  &
        index_valid[4]  &
        index_valid[5]  &
        index_valid[6]  &
        index_valid[7]  &
        index_valid[8]  &
        index_valid[9]  &
        index_valid[10] &
        index_valid[11] &
        index_valid[12] &
        index_valid[13] &
        index_valid[14] &
        index_valid[15] &
        index_valid[16] &
        index_valid[17] &
        index_valid[18] &
        index_valid[19] &
        index_valid[20] &
        index_valid[21] &
        index_valid[22] &
        index_valid[23] &
        index_valid[24] &
        index_valid[25] &
        index_valid[26] &
        index_valid[27] &
        index_valid[28] &
        index_valid[29] &
        index_valid[30] &
        index_valid[31];


    // ============================================================
    // Output mapping
    // ============================================================

    assign sample_index_0  = sample_index[0];
    assign sample_index_1  = sample_index[1];
    assign sample_index_2  = sample_index[2];
    assign sample_index_3  = sample_index[3];
    assign sample_index_4  = sample_index[4];
    assign sample_index_5  = sample_index[5];
    assign sample_index_6  = sample_index[6];
    assign sample_index_7  = sample_index[7];
    assign sample_index_8  = sample_index[8];
    assign sample_index_9  = sample_index[9];
    assign sample_index_10 = sample_index[10];
    assign sample_index_11 = sample_index[11];
    assign sample_index_12 = sample_index[12];
    assign sample_index_13 = sample_index[13];
    assign sample_index_14 = sample_index[14];
    assign sample_index_15 = sample_index[15];
    assign sample_index_16 = sample_index[16];
    assign sample_index_17 = sample_index[17];
    assign sample_index_18 = sample_index[18];
    assign sample_index_19 = sample_index[19];
    assign sample_index_20 = sample_index[20];
    assign sample_index_21 = sample_index[21];
    assign sample_index_22 = sample_index[22];
    assign sample_index_23 = sample_index[23];
    assign sample_index_24 = sample_index[24];
    assign sample_index_25 = sample_index[25];
    assign sample_index_26 = sample_index[26];
    assign sample_index_27 = sample_index[27];
    assign sample_index_28 = sample_index[28];
    assign sample_index_29 = sample_index[29];
    assign sample_index_30 = sample_index[30];
    assign sample_index_31 = sample_index[31];

endmodule