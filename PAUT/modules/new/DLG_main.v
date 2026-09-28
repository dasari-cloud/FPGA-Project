`timescale 1ns/1ps

//======================================================================
// DLG.v
// PAUT TRANSMIT DELAY LAW GENERATOR
//
// Physical array : 32 elements
// Pitch          : 0.6 mm
// Active TX      : 8 elements
// Apertures      : 25
//
// aperture_idx:
//   0  -> E0  - E7
//   1  -> E1  - E8
//   ...
//   24 -> E24 - E31
//
// Aperture center:
//   xc = (aperture_idx - 12) * 0.6 mm
//
// Focal point:
//   xf = xc + F*sin(theta)
//   zf = F*cos(theta)
//
// Distance:
//   d_i = sqrt((xf-x_i)^2 + zf^2)
//
// Delay:
//   delta_d_i = d_max - d_i
//   delay_i   = delta_d_i / 6.32
//
// All arithmetic = IEEE-754 FLOAT32
//
// Existing verified IP latencies:
//   MULT = 9
//   ADD  = 12
//   SUB  = 12
//   SQRT = 29
//
//======================================================================

module DLG (

    input wire clk,
    input wire rst_n,

    input wire in_valid,

    // 0 ... 24
    input wire [4:0] aperture_idx,

    // Focus in mm
    input wire [31:0] focus,

    // From SAG
    input wire [31:0] sin_theta,
    input wire [31:0] cos_theta,


    // Focal point
    output wire focal_valid,

    output wire [31:0] x_focus,
    output wire [31:0] z_focus,


    // Distances
    output wire distances_valid,

    output wire [31:0] distance_0,
    output wire [31:0] distance_1,
    output wire [31:0] distance_2,
    output wire [31:0] distance_3,
    output wire [31:0] distance_4,
    output wire [31:0] distance_5,
    output wire [31:0] distance_6,
    output wire [31:0] distance_7,


    // Maximum distance
    output wire dmax_valid,
    output wire [31:0] d_max,


    // Delta distance
    output wire delta_valid,

    output wire [31:0] delta_d0,
    output wire [31:0] delta_d1,
    output wire [31:0] delta_d2,
    output wire [31:0] delta_d3,
    output wire [31:0] delta_d4,
    output wire [31:0] delta_d5,
    output wire [31:0] delta_d6,
    output wire [31:0] delta_d7,


    // Final TX delays in microseconds
    output wire delay_valid,

    output wire [31:0] delay_0,
    output wire [31:0] delay_1,
    output wire [31:0] delay_2,
    output wire [31:0] delay_3,
    output wire [31:0] delay_4,
    output wire [31:0] delay_5,
    output wire [31:0] delay_6,
    output wire [31:0] delay_7

);


//======================================================================
// CONSTANTS
//======================================================================

localparam MULT_LATENCY = 9;
localparam ADD_LATENCY  = 12;
localparam SUB_LATENCY  = 12;
localparam SQRT_LATENCY = 29;

// 1 / 6.32 mm/us
localparam [31:0] INV_C = 32'h3E22067B;


//======================================================================
// 32-ELEMENT POSITION LUT
//
// x(n) = (n - 15.5) * 0.6 mm
//======================================================================

function [31:0] element_position;

    input [5:0] index;

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


//======================================================================
// APERTURE CENTER LUT
//
// A0  = -7.2 mm
// A12 =  0.0 mm
// A24 = +7.2 mm
//======================================================================

function [31:0] aperture_center;

    input [4:0] index;

    begin

        case (index)

             0: aperture_center = 32'hC0E66666; // -7.2
             1: aperture_center = 32'hC0D33333; // -6.6
             2: aperture_center = 32'hC0C00000; // -6.0
             3: aperture_center = 32'hC0ACCCCD; // -5.4
             4: aperture_center = 32'hC099999A; // -4.8
             5: aperture_center = 32'hC0866666; // -4.2
             6: aperture_center = 32'hC0666666; // -3.6
             7: aperture_center = 32'hC0400000; // -3.0

             8: aperture_center = 32'hC019999A; // -2.4
             9: aperture_center = 32'hBFE66666; // -1.8
            10: aperture_center = 32'hBF99999A; // -1.2
            11: aperture_center = 32'hBF19999A; // -0.6

            12: aperture_center = 32'h00000000; //  0.0

            13: aperture_center = 32'h3F19999A; // +0.6
            14: aperture_center = 32'h3F99999A; // +1.2
            15: aperture_center = 32'h3FE66666; // +1.8
            16: aperture_center = 32'h4019999A; // +2.4
            17: aperture_center = 32'h40400000; // +3.0
            18: aperture_center = 32'h40666666; // +3.6
            19: aperture_center = 32'h40866666; // +4.2
            20: aperture_center = 32'h4099999A; // +4.8
            21: aperture_center = 32'h40ACCCCD; // +5.4
            22: aperture_center = 32'h40C00000; // +6.0
            23: aperture_center = 32'h40D33333; // +6.6
            24: aperture_center = 32'h40E66666; // +7.2

            default:
                aperture_center = 32'h00000000;

        endcase

    end

endfunction


//======================================================================
// CURRENT EVENT GEOMETRY
//======================================================================

wire [31:0] x_center_event;

assign x_center_event =
    aperture_center(aperture_idx);


// Eight physical element coordinates belonging to current event

wire [31:0] elem_x_event [0:7];

assign elem_x_event[0] =
    element_position({1'b0, aperture_idx} + 6'd0);

assign elem_x_event[1] =
    element_position({1'b0, aperture_idx} + 6'd1);

assign elem_x_event[2] =
    element_position({1'b0, aperture_idx} + 6'd2);

assign elem_x_event[3] =
    element_position({1'b0, aperture_idx} + 6'd3);

assign elem_x_event[4] =
    element_position({1'b0, aperture_idx} + 6'd4);

assign elem_x_event[5] =
    element_position({1'b0, aperture_idx} + 6'd5);

assign elem_x_event[6] =
    element_position({1'b0, aperture_idx} + 6'd6);

assign elem_x_event[7] =
    element_position({1'b0, aperture_idx} + 6'd7);


//======================================================================
//
// FOCAL POINT
//
//======================================================================

wire [31:0] f_sin;
wire [31:0] f_cos;

wire f_sin_valid;
wire f_cos_valid;


//======================================================================
// F1
//
// Fsin = F*sin(theta)
// Fcos = F*cos(theta)
//======================================================================

floating_point_mult mult_f_sin (

    .aclk(clk),

    .s_axis_a_tvalid(in_valid),
    .s_axis_a_tdata(focus),

    .s_axis_b_tvalid(in_valid),
    .s_axis_b_tdata(sin_theta),

    .m_axis_result_tvalid(f_sin_valid),
    .m_axis_result_tdata(f_sin)

);


floating_point_mult mult_f_cos (

    .aclk(clk),

    .s_axis_a_tvalid(in_valid),
    .s_axis_a_tdata(focus),

    .s_axis_b_tvalid(in_valid),
    .s_axis_b_tdata(cos_theta),

    .m_axis_result_tvalid(f_cos_valid),
    .m_axis_result_tdata(f_cos)

);


//======================================================================
// PIPE APERTURE CENTER THROUGH MULTIPLIER LATENCY
//======================================================================

reg [31:0] x_center_pipe [0:MULT_LATENCY-1];

integer i;


always @(posedge clk) begin

    if (!rst_n) begin

        for (i = 0; i < MULT_LATENCY; i = i + 1)
            x_center_pipe[i] <= 32'h00000000;

    end

    else begin

        if (in_valid)
            x_center_pipe[0] <= x_center_event;

        for (i = 1; i < MULT_LATENCY; i = i + 1)
            x_center_pipe[i] <= x_center_pipe[i-1];

    end

end


//======================================================================
// F2
//
// xf = xc + Fsin
//======================================================================

wire [31:0] xf_result;
wire xf_valid;


floating_point_add add_x_focus (

    .aclk(clk),

    .s_axis_a_tvalid(f_sin_valid),
    .s_axis_a_tdata(
        x_center_pipe[MULT_LATENCY-1]
    ),

    .s_axis_b_tvalid(f_sin_valid),
    .s_axis_b_tdata(f_sin),

    .m_axis_result_tvalid(xf_valid),
    .m_axis_result_tdata(xf_result)

);


//======================================================================
// ALIGN zf = Fcos WITH xf
//======================================================================

reg [31:0] z_focus_pipe [0:ADD_LATENCY-1];
reg        z_valid_pipe [0:ADD_LATENCY-1];

integer j;


always @(posedge clk) begin

    if (!rst_n) begin

        for (j = 0; j < ADD_LATENCY; j = j + 1) begin

            z_focus_pipe[j] <= 32'h00000000;
            z_valid_pipe[j] <= 1'b0;

        end

    end

    else begin

        z_focus_pipe[0] <= f_cos;
        z_valid_pipe[0] <= f_cos_valid;

        for (j = 1; j < ADD_LATENCY; j = j + 1) begin

            z_focus_pipe[j] <=
                z_focus_pipe[j-1];

            z_valid_pipe[j] <=
                z_valid_pipe[j-1];

        end

    end

end


assign x_focus =
    xf_result;

assign z_focus =
    z_focus_pipe[ADD_LATENCY-1];

assign focal_valid =
    xf_valid &
    z_valid_pipe[ADD_LATENCY-1];


//======================================================================
// ELEMENT POSITION METADATA PIPELINE
//
// Focal point appears:
//
// MULT 9 + ADD 12 = 21 clocks after input.
//
// Therefore element positions must travel with the same event.
//
// This is necessary when aperture_idx changes every clock.
//======================================================================

localparam FOCAL_LATENCY =
    MULT_LATENCY + ADD_LATENCY;


reg [31:0] elem_pipe0 [0:FOCAL_LATENCY-1];
reg [31:0] elem_pipe1 [0:FOCAL_LATENCY-1];
reg [31:0] elem_pipe2 [0:FOCAL_LATENCY-1];
reg [31:0] elem_pipe3 [0:FOCAL_LATENCY-1];
reg [31:0] elem_pipe4 [0:FOCAL_LATENCY-1];
reg [31:0] elem_pipe5 [0:FOCAL_LATENCY-1];
reg [31:0] elem_pipe6 [0:FOCAL_LATENCY-1];
reg [31:0] elem_pipe7 [0:FOCAL_LATENCY-1];

reg elem_meta_valid [0:FOCAL_LATENCY-1];

integer e;


always @(posedge clk) begin

    if (!rst_n) begin

        for (e = 0; e < FOCAL_LATENCY; e = e + 1) begin

            elem_pipe0[e] <= 32'h00000000;
            elem_pipe1[e] <= 32'h00000000;
            elem_pipe2[e] <= 32'h00000000;
            elem_pipe3[e] <= 32'h00000000;

            elem_pipe4[e] <= 32'h00000000;
            elem_pipe5[e] <= 32'h00000000;
            elem_pipe6[e] <= 32'h00000000;
            elem_pipe7[e] <= 32'h00000000;

            elem_meta_valid[e] <= 1'b0;

        end

    end

    else begin

        //--------------------------------------------------------------
        // Capture event
        //--------------------------------------------------------------

        if (in_valid) begin

            elem_pipe0[0] <= elem_x_event[0];
            elem_pipe1[0] <= elem_x_event[1];
            elem_pipe2[0] <= elem_x_event[2];
            elem_pipe3[0] <= elem_x_event[3];

            elem_pipe4[0] <= elem_x_event[4];
            elem_pipe5[0] <= elem_x_event[5];
            elem_pipe6[0] <= elem_x_event[6];
            elem_pipe7[0] <= elem_x_event[7];

        end

        elem_meta_valid[0] <= in_valid;


        //--------------------------------------------------------------
        // Pipeline metadata
        //--------------------------------------------------------------

        for (e = 1; e < FOCAL_LATENCY; e = e + 1) begin

            elem_pipe0[e] <= elem_pipe0[e-1];
            elem_pipe1[e] <= elem_pipe1[e-1];
            elem_pipe2[e] <= elem_pipe2[e-1];
            elem_pipe3[e] <= elem_pipe3[e-1];

            elem_pipe4[e] <= elem_pipe4[e-1];
            elem_pipe5[e] <= elem_pipe5[e-1];
            elem_pipe6[e] <= elem_pipe6[e-1];
            elem_pipe7[e] <= elem_pipe7[e-1];

            elem_meta_valid[e] <= elem_meta_valid[e-1];

        end

    end

end


//======================================================================
// ELEMENT POSITIONS ALIGNED WITH FOCAL POINT
//======================================================================

wire [31:0] elem_x [0:7];

assign elem_x[0] = elem_pipe0[FOCAL_LATENCY-1];
assign elem_x[1] = elem_pipe1[FOCAL_LATENCY-1];
assign elem_x[2] = elem_pipe2[FOCAL_LATENCY-1];
assign elem_x[3] = elem_pipe3[FOCAL_LATENCY-1];

assign elem_x[4] = elem_pipe4[FOCAL_LATENCY-1];
assign elem_x[5] = elem_pipe5[FOCAL_LATENCY-1];
assign elem_x[6] = elem_pipe6[FOCAL_LATENCY-1];
assign elem_x[7] = elem_pipe7[FOCAL_LATENCY-1];


wire distance_input_valid;

assign distance_input_valid =
    focal_valid &
    elem_meta_valid[FOCAL_LATENCY-1];


//======================================================================
//
// DISTANCE STAGE D1
//
// dx_i = xf - xi
//
//======================================================================

wire [31:0] dx [0:7];
wire        dx_valid [0:7];

genvar g;


generate

    for (g = 0; g < 8; g = g + 1) begin : GEN_DX

        floating_point_sub sub_dx (

            .aclk(clk),

            .s_axis_a_tvalid(
                distance_input_valid
            ),

            .s_axis_a_tdata(
                x_focus
            ),

            .s_axis_b_tvalid(
                distance_input_valid
            ),

            .s_axis_b_tdata(
                elem_x[g]
            ),

            .m_axis_result_tvalid(
                dx_valid[g]
            ),

            .m_axis_result_tdata(
                dx[g]
            )

        );

    end

endgenerate


//======================================================================
// D2A
//
// dx_i^2
//======================================================================

wire [31:0] dx_sq [0:7];
wire        dx_sq_valid [0:7];


generate

    for (g = 0; g < 8; g = g + 1) begin : GEN_DX_SQUARE

        floating_point_mult mult_dx_sq (

            .aclk(clk),

            .s_axis_a_tvalid(
                dx_valid[g]
            ),

            .s_axis_a_tdata(
                dx[g]
            ),

            .s_axis_b_tvalid(
                dx_valid[g]
            ),

            .s_axis_b_tdata(
                dx[g]
            ),

            .m_axis_result_tvalid(
                dx_sq_valid[g]
            ),

            .m_axis_result_tdata(
                dx_sq[g]
            )

        );

    end

endgenerate


//======================================================================
// D2B
//
// z^2
//======================================================================

wire [31:0] z_sq_early;
wire z_sq_early_valid;


floating_point_mult mult_z_sq (

    .aclk(clk),

    .s_axis_a_tvalid(
        distance_input_valid
    ),

    .s_axis_a_tdata(
        z_focus
    ),

    .s_axis_b_tvalid(
        distance_input_valid
    ),

    .s_axis_b_tdata(
        z_focus
    ),

    .m_axis_result_tvalid(
        z_sq_early_valid
    ),

    .m_axis_result_tdata(
        z_sq_early
    )

);


//======================================================================
// ALIGN z^2 WITH dx^2
//
// dx path:
// SUB 12 + MULT 9
//
// z path:
// MULT 9
//
// Extra delay = 12
//======================================================================

reg [31:0] z_sq_pipe [0:SUB_LATENCY-1];
reg z_sq_valid_pipe [0:SUB_LATENCY-1];

integer k;


always @(posedge clk) begin

    if (!rst_n) begin

        for (k = 0; k < SUB_LATENCY; k = k + 1) begin

            z_sq_pipe[k] <= 32'h00000000;
            z_sq_valid_pipe[k] <= 1'b0;

        end

    end

    else begin

        z_sq_pipe[0] <= z_sq_early;
        z_sq_valid_pipe[0] <= z_sq_early_valid;


        for (k = 1; k < SUB_LATENCY; k = k + 1) begin

            z_sq_pipe[k] <= z_sq_pipe[k-1];

            z_sq_valid_pipe[k] <=
                z_sq_valid_pipe[k-1];

        end

    end

end


wire [31:0] z_sq;
wire z_sq_valid;


assign z_sq =
    z_sq_pipe[SUB_LATENCY-1];

assign z_sq_valid =
    z_sq_valid_pipe[SUB_LATENCY-1];


//======================================================================
// D3
//
// r^2 = dx^2 + z^2
//======================================================================

wire [31:0] radius_sq [0:7];
wire        radius_sq_valid [0:7];

wire radius_input_valid [0:7];


generate

    for (g = 0; g < 8; g = g + 1) begin : GEN_RADIUS_SQ

        assign radius_input_valid[g] =
            dx_sq_valid[g] &
            z_sq_valid;


        floating_point_add add_radius_sq (

            .aclk(clk),

            .s_axis_a_tvalid(
                radius_input_valid[g]
            ),

            .s_axis_a_tdata(
                dx_sq[g]
            ),

            .s_axis_b_tvalid(
                radius_input_valid[g]
            ),

            .s_axis_b_tdata(
                z_sq
            ),

            .m_axis_result_tvalid(
                radius_sq_valid[g]
            ),

            .m_axis_result_tdata(
                radius_sq[g]
            )

        );

    end

endgenerate


//======================================================================
// D4
//
// d_i = sqrt(r^2)
//======================================================================

wire [31:0] distance [0:7];
wire        distance_valid [0:7];


generate

    for (g = 0; g < 8; g = g + 1) begin : GEN_SQRT

        floating_point_sqrt sqrt_distance (

            .aclk(clk),

            .s_axis_a_tvalid(
                radius_sq_valid[g]
            ),

            .s_axis_a_tdata(
                radius_sq[g]
            ),

            .m_axis_result_tvalid(
                distance_valid[g]
            ),

            .m_axis_result_tdata(
                distance[g]
            )

        );

    end

endgenerate


assign distances_valid =

      distance_valid[0]
    & distance_valid[1]
    & distance_valid[2]
    & distance_valid[3]
    & distance_valid[4]
    & distance_valid[5]
    & distance_valid[6]
    & distance_valid[7];


//======================================================================
//
// D_MAX
//
// Positive FLOAT32 values:
// unsigned comparison preserves ordering.
//
//======================================================================


// LEVEL 1

reg [31:0] max01;
reg [31:0] max23;
reg [31:0] max45;
reg [31:0] max67;

reg max_l1_valid;


always @(posedge clk) begin

    if (!rst_n) begin

        max01 <= 0;
        max23 <= 0;
        max45 <= 0;
        max67 <= 0;

        max_l1_valid <= 0;

    end

    else begin

        max_l1_valid <=
            distances_valid;

        if (distances_valid) begin

            if (distance[0] >= distance[1])
                max01 <= distance[0];
            else
                max01 <= distance[1];


            if (distance[2] >= distance[3])
                max23 <= distance[2];
            else
                max23 <= distance[3];


            if (distance[4] >= distance[5])
                max45 <= distance[4];
            else
                max45 <= distance[5];


            if (distance[6] >= distance[7])
                max67 <= distance[6];
            else
                max67 <= distance[7];

        end

    end

end


//======================================================================
// LEVEL 2
//======================================================================

reg [31:0] max0123;
reg [31:0] max4567;

reg max_l2_valid;


always @(posedge clk) begin

    if (!rst_n) begin

        max0123 <= 0;
        max4567 <= 0;

        max_l2_valid <= 0;

    end

    else begin

        max_l2_valid <=
            max_l1_valid;

        if (max_l1_valid) begin

            if (max01 >= max23)
                max0123 <= max01;
            else
                max0123 <= max23;


            if (max45 >= max67)
                max4567 <= max45;
            else
                max4567 <= max67;

        end

    end

end


//======================================================================
// LEVEL 3
//======================================================================

reg [31:0] d_max_reg;
reg dmax_valid_reg;


always @(posedge clk) begin

    if (!rst_n) begin

        d_max_reg <= 0;
        dmax_valid_reg <= 0;

    end

    else begin

        dmax_valid_reg <=
            max_l2_valid;

        if (max_l2_valid) begin

            if (max0123 >= max4567)
                d_max_reg <= max0123;
            else
                d_max_reg <= max4567;

        end

    end

end


assign d_max =
    d_max_reg;

assign dmax_valid =
    dmax_valid_reg;


//======================================================================
//
// DISTANCE ALIGNMENT FOR DELTA STAGE
//
// d_max requires 3 clocks.
//
//======================================================================

reg [31:0] distance_delay1 [0:7];
reg [31:0] distance_delay2 [0:7];
reg [31:0] distance_delay3 [0:7];

reg distance_delay_valid1;
reg distance_delay_valid2;
reg distance_delay_valid3;

integer m;


always @(posedge clk) begin

    if (!rst_n) begin

        distance_delay_valid1 <= 0;
        distance_delay_valid2 <= 0;
        distance_delay_valid3 <= 0;


        for (m = 0; m < 8; m = m + 1) begin

            distance_delay1[m] <= 0;
            distance_delay2[m] <= 0;
            distance_delay3[m] <= 0;

        end

    end

    else begin

        distance_delay_valid1 <=
            distances_valid;

        distance_delay_valid2 <=
            distance_delay_valid1;

        distance_delay_valid3 <=
            distance_delay_valid2;


        if (distances_valid) begin

            for (m = 0; m < 8; m = m + 1)
                distance_delay1[m] <=
                    distance[m];

        end


        if (distance_delay_valid1) begin

            for (m = 0; m < 8; m = m + 1)
                distance_delay2[m] <=
                    distance_delay1[m];

        end


        if (distance_delay_valid2) begin

            for (m = 0; m < 8; m = m + 1)
                distance_delay3[m] <=
                    distance_delay2[m];

        end

    end

end


wire delta_input_valid;

assign delta_input_valid =
    dmax_valid;


//======================================================================
//
// DELTA DISTANCE
//
// delta_i = d_max - d_i
//
//======================================================================

wire [31:0] delta_distance [0:7];
wire delta_distance_valid [0:7];

genvar h;


generate

    for (h = 0; h < 8; h = h + 1) begin : GEN_DELTA_DISTANCE

        floating_point_sub sub_delta_distance (

            .aclk(clk),
            .aresetn(rst_n),

            .s_axis_a_tvalid(
                delta_input_valid
            ),

            .s_axis_a_tdata(
                d_max
            ),

            .s_axis_b_tvalid(
                delta_input_valid
            ),

            .s_axis_b_tdata(
                distance_delay3[h]
            ),

            .m_axis_result_tvalid(
                delta_distance_valid[h]
            ),

            .m_axis_result_tdata(
                delta_distance[h]
            )

        );

    end

endgenerate


assign delta_valid =

      delta_distance_valid[0]
    & delta_distance_valid[1]
    & delta_distance_valid[2]
    & delta_distance_valid[3]
    & delta_distance_valid[4]
    & delta_distance_valid[5]
    & delta_distance_valid[6]
    & delta_distance_valid[7];


//======================================================================
//
// FINAL TX DELAY
//
// delay_i = delta_i / 6.32
//         = delta_i * INV_C
//
//======================================================================

wire [31:0] delay_internal [0:7];
wire delay_internal_valid [0:7];

genvar p;


generate

    for (p = 0; p < 8; p = p + 1) begin : GEN_FINAL_DELAY

        floating_point_mult mult_final_delay (

            .aclk(clk),

            .s_axis_a_tvalid(
                delta_valid
            ),

            .s_axis_a_tdata(
                delta_distance[p]
            ),

            .s_axis_b_tvalid(
                delta_valid
            ),

            .s_axis_b_tdata(
                INV_C
            ),

            .m_axis_result_tvalid(
                delay_internal_valid[p]
            ),

            .m_axis_result_tdata(
                delay_internal[p]
            )

        );

    end

endgenerate


assign delay_valid =

      delay_internal_valid[0]
    & delay_internal_valid[1]
    & delay_internal_valid[2]
    & delay_internal_valid[3]
    & delay_internal_valid[4]
    & delay_internal_valid[5]
    & delay_internal_valid[6]
    & delay_internal_valid[7];


//======================================================================
// OUTPUT ASSIGNMENTS
//======================================================================

assign distance_0 = distance[0];
assign distance_1 = distance[1];
assign distance_2 = distance[2];
assign distance_3 = distance[3];

assign distance_4 = distance[4];
assign distance_5 = distance[5];
assign distance_6 = distance[6];
assign distance_7 = distance[7];


assign delta_d0 = delta_distance[0];
assign delta_d1 = delta_distance[1];
assign delta_d2 = delta_distance[2];
assign delta_d3 = delta_distance[3];

assign delta_d4 = delta_distance[4];
assign delta_d5 = delta_distance[5];
assign delta_d6 = delta_distance[6];
assign delta_d7 = delta_distance[7];


assign delay_0 = delay_internal[0];
assign delay_1 = delay_internal[1];
assign delay_2 = delay_internal[2];
assign delay_3 = delay_internal[3];

assign delay_4 = delay_internal[4];
assign delay_5 = delay_internal[5];
assign delay_6 = delay_internal[6];
assign delay_7 = delay_internal[7];


endmodule