`timescale 1ns / 1ps

// ============================================================================
// DAS DELAY CALCULATOR - STAGE 1
//
// Function:
//   For one image pixel (x,z), calculate receive propagation time
//   from that pixel to all 32 array elements.
//
//   dx_j      = x_pixel - x_element[j]
//   distance  = sqrt(dx_j^2 + z_pixel^2)
//   rx_time   = distance * (1/c)
//
// Units:
//   x, z, distance : mm
//   c              : mm/us
//   rx_time        : us
//
// Array:
//   32 elements
//   pitch = 0.6 mm
//   positions = -9.3 mm ... +9.3 mm
//
// Architecture:
//   32 fully-parallel RX lanes
//   Fully pipelined floating-point datapath
//
// Input throughput target:
//   1 pixel / clock after pipeline fill
// ============================================================================

module das_delay (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        pixel_valid,
    input  wire [31:0] x_pixel,
    input  wire [31:0] z_pixel,

    output wire        rx_time_valid,

    output wire [31:0] rx_time_0,
    output wire [31:0] rx_time_1,
    output wire [31:0] rx_time_2,
    output wire [31:0] rx_time_3,
    output wire [31:0] rx_time_4,
    output wire [31:0] rx_time_5,
    output wire [31:0] rx_time_6,
    output wire [31:0] rx_time_7,
    output wire [31:0] rx_time_8,
    output wire [31:0] rx_time_9,
    output wire [31:0] rx_time_10,
    output wire [31:0] rx_time_11,
    output wire [31:0] rx_time_12,
    output wire [31:0] rx_time_13,
    output wire [31:0] rx_time_14,
    output wire [31:0] rx_time_15,
    output wire [31:0] rx_time_16,
    output wire [31:0] rx_time_17,
    output wire [31:0] rx_time_18,
    output wire [31:0] rx_time_19,
    output wire [31:0] rx_time_20,
    output wire [31:0] rx_time_21,
    output wire [31:0] rx_time_22,
    output wire [31:0] rx_time_23,
    output wire [31:0] rx_time_24,
    output wire [31:0] rx_time_25,
    output wire [31:0] rx_time_26,
    output wire [31:0] rx_time_27,
    output wire [31:0] rx_time_28,
    output wire [31:0] rx_time_29,
    output wire [31:0] rx_time_30,
    output wire [31:0] rx_time_31
);

    // ========================================================================
    // Constants
    // ========================================================================

    // 1 / 6.32 mm/us
    // Verified float32 constant from DLG.
    localparam [31:0] INV_C = 32'h3E22067B;

    // ========================================================================
    // Element position LUT
    // ========================================================================

    function [31:0] element_position;
        input [4:0] index;

        begin
            case (index)

                 0: element_position = 32'hC114CCCD; // -9.3
                 1: element_position = 32'hC10B3333; // -8.7
                 2: element_position = 32'hC101999A; // -8.1
                 3: element_position = 32'hC0F00000; // -7.5
                 4: element_position = 32'hC0DCCCCD; // -6.9
                 5: element_position = 32'hC0C9999A; // -6.3
                 6: element_position = 32'hC0B66666; // -5.7
                 7: element_position = 32'hC0A33333; // -5.1

                 8: element_position = 32'hC0900000; // -4.5
                 9: element_position = 32'hC079999A; // -3.9
                10: element_position = 32'hC0533333; // -3.3
                11: element_position = 32'hC02CCCCD; // -2.7
                12: element_position = 32'hC0066666; // -2.1
                13: element_position = 32'hBFC00000; // -1.5
                14: element_position = 32'hBF666666; // -0.9
                15: element_position = 32'hBE99999A; // -0.3

                16: element_position = 32'h3E99999A; // +0.3
                17: element_position = 32'h3F666666; // +0.9
                18: element_position = 32'h3FC00000; // +1.5
                19: element_position = 32'h40066666; // +2.1
                20: element_position = 32'h402CCCCD; // +2.7
                21: element_position = 32'h40533333; // +3.3
                22: element_position = 32'h4079999A; // +3.9
                23: element_position = 32'h40900000; // +4.5

                24: element_position = 32'h40A33333; // +5.1
                25: element_position = 32'h40B66666; // +5.7
                26: element_position = 32'h40C9999A; // +6.3
                27: element_position = 32'h40DCCCCD; // +6.9
                28: element_position = 32'h40F00000; // +7.5
                29: element_position = 32'h4101999A; // +8.1
                30: element_position = 32'h410B3333; // +8.7
                31: element_position = 32'h4114CCCD; // +9.3

                default: element_position = 32'h00000000;

            endcase
        end
    endfunction


    // ========================================================================
    // Internal buses
    // ========================================================================

    wire [31:0] dx           [0:31];
    wire [31:0] dx_sq        [0:31];
    wire [31:0] radius_sq    [0:31];
    wire [31:0] distance     [0:31];
    wire [31:0] rx_time      [0:31];

    wire dx_valid            [0:31];
    wire dx_sq_valid         [0:31];
    wire radius_sq_valid     [0:31];
    wire distance_valid      [0:31];
    wire rx_time_lane_valid  [0:31];


    // ========================================================================
    // z^2 shared calculation
    //
    // z is identical for all 32 receiver lanes, therefore calculate z^2 only
    // once instead of using 32 extra multipliers.
    // ========================================================================

    wire [31:0] z_sq;
    wire        z_sq_raw_valid;

    floating_point_mult mult_z_sq (
        .aclk                  (clk),

        .s_axis_a_tvalid       (pixel_valid),
        .s_axis_a_tdata        (z_pixel),

        .s_axis_b_tvalid       (pixel_valid),
        .s_axis_b_tdata        (z_pixel),

        .m_axis_result_tvalid  (z_sq_raw_valid),
        .m_axis_result_tdata   (z_sq)
    );


    // ========================================================================
    // z^2 VALID ALIGNMENT
    //
    // dx path:
    //   SUB = 12 clocks
    //   MUL =  9 clocks
    //
    // z^2 path:
    //   MUL = 9 clocks
    //
    // Therefore z^2 arrives 12 clocks earlier than dx^2.
    //
    // Delay z^2 data + valid by 12 clocks.
    // ========================================================================

    reg [31:0] z_sq_data_pipe [0:11];
    reg [11:0] z_sq_valid_pipe;

    integer k;

    always @(posedge clk) begin
        if (!rst_n) begin

            z_sq_valid_pipe <= 12'b0;

            for (k = 0; k < 12; k = k + 1)
                z_sq_data_pipe[k] <= 32'b0;

        end
        else begin

            z_sq_valid_pipe[0] <= z_sq_raw_valid;
            z_sq_data_pipe[0]  <= z_sq;

            for (k = 1; k < 12; k = k + 1) begin
                z_sq_valid_pipe[k] <= z_sq_valid_pipe[k-1];
                z_sq_data_pipe[k]  <= z_sq_data_pipe[k-1];
            end

        end
    end

    wire [31:0] z_sq_aligned;
    wire        z_sq_aligned_valid;

    assign z_sq_aligned       = z_sq_data_pipe[11];
    assign z_sq_aligned_valid = z_sq_valid_pipe[11];


    // ========================================================================
    // 32 PARALLEL RECEIVE LANES
    // ========================================================================

    genvar g;

    generate
        for (g = 0; g < 32; g = g + 1) begin : RX_LANES

            // ================================================================
            // Stage RX1
            //
            // dx = x_pixel - x_element
            //
            // Latency = 12 clocks
            // ================================================================

            floating_point_sub sub_dx (
                .aclk                  (clk),

                .s_axis_a_tvalid       (pixel_valid),
                .s_axis_a_tdata        (x_pixel),

                .s_axis_b_tvalid       (pixel_valid),
                .s_axis_b_tdata        (element_position(g)),

                .m_axis_result_tvalid  (dx_valid[g]),
                .m_axis_result_tdata   (dx[g])
            );


            // ================================================================
            // Stage RX2
            //
            // dx^2
            //
            // Latency = 9 clocks
            // ================================================================

            floating_point_mult mult_dx_sq (
                .aclk                  (clk),

                .s_axis_a_tvalid       (dx_valid[g]),
                .s_axis_a_tdata        (dx[g]),

                .s_axis_b_tvalid       (dx_valid[g]),
                .s_axis_b_tdata        (dx[g]),

                .m_axis_result_tvalid  (dx_sq_valid[g]),
                .m_axis_result_tdata   (dx_sq[g])
            );


            // ================================================================
            // Stage RX3
            //
            // radius_sq = dx^2 + z^2
            //
            // IMPORTANT:
            // Use common valid exactly like the verified DLG implementation.
            //
            // Latency = 12 clocks
            // ================================================================

            wire radius_input_valid;

            assign radius_input_valid =
                       dx_sq_valid[g] &
                       z_sq_aligned_valid;

            floating_point_add add_radius_sq (
                .aclk                  (clk),

                .s_axis_a_tvalid       (radius_input_valid),
                .s_axis_a_tdata        (dx_sq[g]),

                .s_axis_b_tvalid       (radius_input_valid),
                .s_axis_b_tdata        (z_sq_aligned),

                .m_axis_result_tvalid  (radius_sq_valid[g]),
                .m_axis_result_tdata   (radius_sq[g])
            );


            // ================================================================
            // Stage RX4
            //
            // distance = sqrt(radius_sq)
            //
            // Latency = 29 clocks
            // ================================================================

            floating_point_sqrt sqrt_distance (
                .aclk                  (clk),

                .s_axis_a_tvalid       (radius_sq_valid[g]),
                .s_axis_a_tdata        (radius_sq[g]),

                .m_axis_result_tvalid  (distance_valid[g]),
                .m_axis_result_tdata   (distance[g])
            );


            // ================================================================
            // Stage RX5
            //
            // rx_time = distance / c
            //         = distance * (1/c)
            //
            // INV_C = 1 / 6.32 mm/us
            //
            // Latency = 9 clocks
            // ================================================================

            floating_point_mult mult_inv_c (
                .aclk                  (clk),

                .s_axis_a_tvalid       (distance_valid[g]),
                .s_axis_a_tdata        (distance[g]),

                .s_axis_b_tvalid       (distance_valid[g]),
                .s_axis_b_tdata        (INV_C),

                .m_axis_result_tvalid  (rx_time_lane_valid[g]),
                .m_axis_result_tdata   (rx_time[g])
            );

        end
    endgenerate


    // ========================================================================
    // Output valid
    //
    // All 32 lanes must be valid together.
    // ========================================================================

    assign rx_time_valid =
           rx_time_lane_valid[0]  &
           rx_time_lane_valid[1]  &
           rx_time_lane_valid[2]  &
           rx_time_lane_valid[3]  &
           rx_time_lane_valid[4]  &
           rx_time_lane_valid[5]  &
           rx_time_lane_valid[6]  &
           rx_time_lane_valid[7]  &
           rx_time_lane_valid[8]  &
           rx_time_lane_valid[9]  &
           rx_time_lane_valid[10] &
           rx_time_lane_valid[11] &
           rx_time_lane_valid[12] &
           rx_time_lane_valid[13] &
           rx_time_lane_valid[14] &
           rx_time_lane_valid[15] &
           rx_time_lane_valid[16] &
           rx_time_lane_valid[17] &
           rx_time_lane_valid[18] &
           rx_time_lane_valid[19] &
           rx_time_lane_valid[20] &
           rx_time_lane_valid[21] &
           rx_time_lane_valid[22] &
           rx_time_lane_valid[23] &
           rx_time_lane_valid[24] &
           rx_time_lane_valid[25] &
           rx_time_lane_valid[26] &
           rx_time_lane_valid[27] &
           rx_time_lane_valid[28] &
           rx_time_lane_valid[29] &
           rx_time_lane_valid[30] &
           rx_time_lane_valid[31];


    // ========================================================================
    // Output mapping
    // ========================================================================

    assign rx_time_0  = rx_time[0];
    assign rx_time_1  = rx_time[1];
    assign rx_time_2  = rx_time[2];
    assign rx_time_3  = rx_time[3];
    assign rx_time_4  = rx_time[4];
    assign rx_time_5  = rx_time[5];
    assign rx_time_6  = rx_time[6];
    assign rx_time_7  = rx_time[7];
    assign rx_time_8  = rx_time[8];
    assign rx_time_9  = rx_time[9];

    assign rx_time_10 = rx_time[10];
    assign rx_time_11 = rx_time[11];
    assign rx_time_12 = rx_time[12];
    assign rx_time_13 = rx_time[13];
    assign rx_time_14 = rx_time[14];
    assign rx_time_15 = rx_time[15];
    assign rx_time_16 = rx_time[16];
    assign rx_time_17 = rx_time[17];
    assign rx_time_18 = rx_time[18];
    assign rx_time_19 = rx_time[19];

    assign rx_time_20 = rx_time[20];
    assign rx_time_21 = rx_time[21];
    assign rx_time_22 = rx_time[22];
    assign rx_time_23 = rx_time[23];
    assign rx_time_24 = rx_time[24];
    assign rx_time_25 = rx_time[25];
    assign rx_time_26 = rx_time[26];
    assign rx_time_27 = rx_time[27];
    assign rx_time_28 = rx_time[28];
    assign rx_time_29 = rx_time[29];

    assign rx_time_30 = rx_time[30];
    assign rx_time_31 = rx_time[31];

endmodule