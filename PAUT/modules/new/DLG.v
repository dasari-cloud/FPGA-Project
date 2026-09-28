//======================================================================
// DLG.v - PAUT Transmit Delay Law Generator
//
// Stage 1:
//   Calculates focal point:
//
//       xf = xc + F*sin(theta)
//       zf = F*cos(theta)
//
// Inputs/outputs:
//   IEEE-754 FLOAT32
//
// Architecture:
//   Parallel floating-point multipliers
//   Pipelined valid propagation
//
// Reference acquisition:
//   N          = 32
//   TX aperture = 8 elements
//   Pitch      = 0.6 mm
//   Focus      = 65 mm
//======================================================================

`timescale 1ns/1ps

module DLG (

    input  wire        clk,
    input  wire        rst_n,

    input  wire        in_valid,

    // Center of active TX aperture
    input  wire [31:0] x_center,

    // Focus distance
    input  wire [31:0] focus,

    // From SAG
    input  wire [31:0] sin_theta,
    input  wire [31:0] cos_theta,

    // Focal point
    output wire        focal_valid,
    output wire [31:0] x_focus,
    output wire [31:0] z_focus
);


    //==================================================================
    // Stage 1
    //
    // Parallel:
    //
    //     Fsin = F * sin(theta)
    //     Fcos = F * cos(theta)
    //
    // These two multiplications happen simultaneously.
    //==================================================================

    wire [31:0] f_sin;
    wire [31:0] f_cos;

    wire        f_sin_valid;
    wire        f_cos_valid;


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


    //==================================================================
    // Pipeline x_center
    //
    // IMPORTANT:
    // x_center must be delayed by the same number of clocks as the
    // floating-point multiplier.
    //
    // Set this to the latency configured in your Vivado FP multiplier.
    //==================================================================

    parameter MULT_LATENCY = 8;

    reg [31:0] x_center_pipe [0:MULT_LATENCY-1];

    integer i;

    always @(posedge clk) begin

        if (!rst_n) begin

            for (i = 0; i < MULT_LATENCY; i = i + 1)
                x_center_pipe[i] <= 32'h00000000;

        end

        else begin

            if (in_valid)
                x_center_pipe[0] <= x_center;

            for (i = 1; i < MULT_LATENCY; i = i + 1)
                x_center_pipe[i] <= x_center_pipe[i-1];

        end

    end


    //==================================================================
    // Stage 2
    //
    // xf = xc + F*sin(theta)
    //
    // zf = F*cos(theta)
    //
    // zf does not need an adder because array z = 0.
    //==================================================================

    wire [31:0] xf_result;
    wire        xf_valid;


    floating_point_add add_x_focus (

        .aclk(clk),

        .s_axis_a_tvalid(f_sin_valid),
        .s_axis_a_tdata(x_center_pipe[MULT_LATENCY-1]),

        .s_axis_b_tvalid(f_sin_valid),
        .s_axis_b_tdata(f_sin),

        .m_axis_result_tvalid(xf_valid),
        .m_axis_result_tdata(xf_result)

    );


    //==================================================================
    // z_focus alignment
    //
    // f_cos is available after Stage 1, while x_focus passes through
    // another floating-point adder.
    //
    // Therefore f_cos must be delayed to match the adder latency.
    //==================================================================

    parameter ADD_LATENCY = 8;

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

                z_focus_pipe[j] <= z_focus_pipe[j-1];
                z_valid_pipe[j] <= z_valid_pipe[j-1];

            end

        end

    end


    //==================================================================
    // Outputs
    //==================================================================

    assign x_focus = xf_result;
    assign z_focus = z_focus_pipe[ADD_LATENCY-1];

    assign focal_valid =
        xf_valid &
        z_valid_pipe[ADD_LATENCY-1];


endmodule