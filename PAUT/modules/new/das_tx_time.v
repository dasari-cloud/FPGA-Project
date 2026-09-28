`timescale 1ns / 1ps

// ============================================================================
// DAS TX TIME
//
// Sliding 8-element TX aperture
// 8 TX paths calculated fully in parallel.
//
// For each active TX element:
//
//   dx_i      = x_pixel - x_element_i
//   distance  = sqrt(dx_i^2 + z_pixel^2)
//   prop_time = distance / c
//   tau_i     = prop_time + tx_delay_i
//
// Equal TX apodization:
//
//   tx_time = (tau_0 + ... + tau_7) / 8
//
// Units:
//   x,z,distance : mm
//   c            : 6.32 mm/us
//   tx_delay     : us
//   tx_time      : us
//
// Architecture:
//   8 parallel TX lanes
//   Fully pipelined
//   3-level pipelined adder tree
//
// Target:
//   II = 1
// ============================================================================

module das_tx_time (

    input  wire        clk,
    input  wire        rst_n,

    input  wire        in_valid,

    input  wire [4:0]  aperture_idx,

    input  wire [31:0] x_pixel,
    input  wire [31:0] z_pixel,

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
    // Constants
    // ========================================================================

    // 1 / 6.32 mm/us
    localparam [31:0] INV_C = 32'h3E22067B;

    // 1 / 8 = 0.125
    localparam [31:0] ONE_EIGHTH = 32'h3E000000;


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

                default:
                    element_position = 32'h00000000;

            endcase

        end

    endfunction


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
    // Internal TX lane signals
    // ========================================================================

    wire [31:0] dx            [0:7];
    wire [31:0] dx_sq         [0:7];
    wire [31:0] radius_sq     [0:7];
    wire [31:0] distance      [0:7];
    wire [31:0] prop_time     [0:7];
    wire [31:0] tau           [0:7];

    wire dx_valid             [0:7];
    wire dx_sq_valid          [0:7];
    wire radius_sq_valid      [0:7];
    wire distance_valid       [0:7];
    wire prop_time_valid      [0:7];
    wire tau_valid            [0:7];


    // ========================================================================
    // Delay DLG delays so they reach the tau adder together with prop_time.
    //
    // Before prop_time:
    //
    // SUB  = 12
    // MUL  =  9
    // ADD  = 12
    // SQRT = 29
    // MUL  =  9
    //
    // Total = 71 clocks
    // ========================================================================

    reg [31:0] delay_pipe_0 [0:70];
    reg [31:0] delay_pipe_1 [0:70];
    reg [31:0] delay_pipe_2 [0:70];
    reg [31:0] delay_pipe_3 [0:70];
    reg [31:0] delay_pipe_4 [0:70];
    reg [31:0] delay_pipe_5 [0:70];
    reg [31:0] delay_pipe_6 [0:70];
    reg [31:0] delay_pipe_7 [0:70];

    integer p;

    always @(posedge clk) begin

        if (!rst_n) begin

            for (p = 0; p < 71; p = p + 1) begin

                delay_pipe_0[p] <= 32'b0;
                delay_pipe_1[p] <= 32'b0;
                delay_pipe_2[p] <= 32'b0;
                delay_pipe_3[p] <= 32'b0;
                delay_pipe_4[p] <= 32'b0;
                delay_pipe_5[p] <= 32'b0;
                delay_pipe_6[p] <= 32'b0;
                delay_pipe_7[p] <= 32'b0;

            end

        end
        else begin

            if (in_valid) begin

                delay_pipe_0[0] <= tx_delay_0;
                delay_pipe_1[0] <= tx_delay_1;
                delay_pipe_2[0] <= tx_delay_2;
                delay_pipe_3[0] <= tx_delay_3;
                delay_pipe_4[0] <= tx_delay_4;
                delay_pipe_5[0] <= tx_delay_5;
                delay_pipe_6[0] <= tx_delay_6;
                delay_pipe_7[0] <= tx_delay_7;

            end

            for (p = 1; p < 71; p = p + 1) begin

                delay_pipe_0[p] <= delay_pipe_0[p-1];
                delay_pipe_1[p] <= delay_pipe_1[p-1];
                delay_pipe_2[p] <= delay_pipe_2[p-1];
                delay_pipe_3[p] <= delay_pipe_3[p-1];
                delay_pipe_4[p] <= delay_pipe_4[p-1];
                delay_pipe_5[p] <= delay_pipe_5[p-1];
                delay_pipe_6[p] <= delay_pipe_6[p-1];
                delay_pipe_7[p] <= delay_pipe_7[p-1];

            end

        end

    end


    // ========================================================================
    // Shared z^2
    // ========================================================================

    wire [31:0] z_sq_raw;
    wire        z_sq_raw_valid;

    floating_point_mult mult_z_sq (

        .aclk                 (clk),

        .s_axis_a_tvalid      (in_valid),
        .s_axis_a_tdata       (z_pixel),

        .s_axis_b_tvalid      (in_valid),
        .s_axis_b_tdata       (z_pixel),

        .m_axis_result_tvalid (z_sq_raw_valid),
        .m_axis_result_tdata  (z_sq_raw)

    );


    // ========================================================================
    // z^2 must be delayed 12 clocks to align with dx^2.
    // ========================================================================

    reg [31:0] z_sq_pipe [0:11];
    reg [11:0] z_sq_valid_pipe;

    integer z;

    always @(posedge clk) begin

        if (!rst_n) begin

            z_sq_valid_pipe <= 12'b0;

            for (z = 0; z < 12; z = z + 1)
                z_sq_pipe[z] <= 32'b0;

        end
        else begin

            z_sq_pipe[0]       <= z_sq_raw;
            z_sq_valid_pipe[0] <= z_sq_raw_valid;

            for (z = 1; z < 12; z = z + 1) begin

                z_sq_pipe[z]       <= z_sq_pipe[z-1];
                z_sq_valid_pipe[z] <= z_sq_valid_pipe[z-1];

            end

        end

    end


    wire [31:0] z_sq_aligned;
    wire        z_sq_aligned_valid;

    assign z_sq_aligned       = z_sq_pipe[11];
    assign z_sq_aligned_valid = z_sq_valid_pipe[11];


    // ========================================================================
    // 8 PARALLEL TX LANES
    // ========================================================================

    genvar g;

    generate

        for (g = 0; g < 8; g = g + 1) begin : TX_LANES

            wire [4:0] element_index;
            wire       radius_input_valid;

            assign element_index = aperture_idx + g;


            // ================================================================
            // TX1 : dx = x_pixel - x_element
            // latency = 12
            // ================================================================

            floating_point_sub sub_dx (

                .aclk                 (clk),

                .s_axis_a_tvalid      (in_valid),
                .s_axis_a_tdata       (x_pixel),

                .s_axis_b_tvalid      (in_valid),
                .s_axis_b_tdata       (element_position(element_index)),

                .m_axis_result_tvalid (dx_valid[g]),
                .m_axis_result_tdata  (dx[g])

            );


            // ================================================================
            // TX2 : dx^2
            // latency = 9
            // ================================================================

            floating_point_mult mult_dx_sq (

                .aclk                 (clk),

                .s_axis_a_tvalid      (dx_valid[g]),
                .s_axis_a_tdata       (dx[g]),

                .s_axis_b_tvalid      (dx_valid[g]),
                .s_axis_b_tdata       (dx[g]),

                .m_axis_result_tvalid (dx_sq_valid[g]),
                .m_axis_result_tdata  (dx_sq[g])

            );


            // ================================================================
            // TX3 : dx^2 + z^2
            // latency = 12
            // ================================================================

            assign radius_input_valid =
                dx_sq_valid[g] &
                z_sq_aligned_valid;

            floating_point_add add_radius_sq (

                .aclk                 (clk),

                .s_axis_a_tvalid      (radius_input_valid),
                .s_axis_a_tdata       (dx_sq[g]),

                .s_axis_b_tvalid      (radius_input_valid),
                .s_axis_b_tdata       (z_sq_aligned),

                .m_axis_result_tvalid (radius_sq_valid[g]),
                .m_axis_result_tdata  (radius_sq[g])

            );


            // ================================================================
            // TX4 : sqrt
            // latency = 29
            // ================================================================

            floating_point_sqrt sqrt_distance (

                .aclk                 (clk),

                .s_axis_a_tvalid      (radius_sq_valid[g]),
                .s_axis_a_tdata       (radius_sq[g]),

                .m_axis_result_tvalid (distance_valid[g]),
                .m_axis_result_tdata  (distance[g])

            );


            // ================================================================
            // TX5 : distance / c
            //     = distance * INV_C
            //
            // latency = 9
            // ================================================================

            floating_point_mult mult_inv_c (

                .aclk                 (clk),

                .s_axis_a_tvalid      (distance_valid[g]),
                .s_axis_a_tdata       (distance[g]),

                .s_axis_b_tvalid      (distance_valid[g]),
                .s_axis_b_tdata       (INV_C),

                .m_axis_result_tvalid (prop_time_valid[g]),
                .m_axis_result_tdata  (prop_time[g])

            );


            // ================================================================
            // TX6 : tau = propagation time + DLG firing delay
            //
            // latency = 12
            // ================================================================

            floating_point_add add_tx_delay (

                .aclk                 (clk),

                .s_axis_a_tvalid      (prop_time_valid[g]),
                .s_axis_a_tdata       (prop_time[g]),

                .s_axis_b_tvalid      (prop_time_valid[g]),
                .s_axis_b_tdata       (
                    (g == 0) ? delay_pipe_0[70] :
                    (g == 1) ? delay_pipe_1[70] :
                    (g == 2) ? delay_pipe_2[70] :
                    (g == 3) ? delay_pipe_3[70] :
                    (g == 4) ? delay_pipe_4[70] :
                    (g == 5) ? delay_pipe_5[70] :
                    (g == 6) ? delay_pipe_6[70] :
                               delay_pipe_7[70]
                ),

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
    // PIPELINED ADDER TREE
    //
    // Level 1:
    // 8 -> 4
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
    // Level 2:
    // 4 -> 2
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
    // Level 3:
    // 2 -> 1
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
    // Divide by 8
    //
    // Average of 8 equal-weight TX paths:
    //
    // tx_time = sum_all * 0.125
    //
    // latency = 9
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