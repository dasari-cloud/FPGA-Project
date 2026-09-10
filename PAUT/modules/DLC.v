`timescale 1ns/1ps

module DLC #(
    parameter real C_MM_US = 5.9
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        elem_valid,
    input  wire [31:0] elem_x,

    input  wire        sin_valid,
    input  wire [31:0] sin_theta,

    output reg         delay_valid,
    output reg  [31:0] delay_us
);

    // ============================================================
    // Convert IEEE-754 float32 to real
    // Simulation/reference purpose
    // ============================================================
    function real f32_to_real;
        input [31:0] f;

        integer exp_int;
        integer mant_int;
        real mant_real;
        real value;

        begin
            if (f == 32'h00000000) begin
                f32_to_real = 0.0;
            end
            else begin

                // Sign
                if (f[31])
                    value = -1.0;
                else
                    value = 1.0;

                // Exponent
                exp_int = f[30:23];

                // Mantissa
                mant_int = f[22:0];

                if (exp_int == 0) begin
                    // Subnormal
                    mant_real = mant_int / 8388608.0;
                    value = value *
                            mant_real *
                            (2.0 ** (-126));
                end
                else begin
                    mant_real = 1.0 +
                                (mant_int / 8388608.0);

                    value = value *
                            mant_real *
                            (2.0 ** (exp_int - 127));
                end

                f32_to_real = value;
            end
        end
    endfunction


    // ============================================================
    // Convert real to IEEE-754 float32
    // Simulation/reference purpose
    // ============================================================
    function [31:0] real_to_f32;
        input real val;

        integer exp_val;
        integer biased_exp;
        integer mant_int;

        real mag;
        real EPS;

        reg        sign_bit;
        reg [7:0]  exponent_bits;
        reg [22:0] mant_bits;

        begin
            EPS = 1.0e-9;

            if (val == 0.0) begin
                real_to_f32 = 32'h00000000;
            end
            else begin

                if (val < 0.0) begin
                    sign_bit = 1'b1;
                    mag = -val;
                end
                else begin
                    sign_bit = 1'b0;
                    mag = val;
                end

                exp_val = 0;

                while (mag >= 2.0) begin
                    mag = mag / 2.0;
                    exp_val = exp_val + 1;
                end

                while (mag < 1.0) begin
                    mag = mag * 2.0;
                    exp_val = exp_val - 1;
                end

                if ((mag - 1.0 < EPS) &&
                    (1.0 - mag < EPS)) begin
                    mag = 1.0;
                end

                mant_int =
                    $rtoi(
                        (mag - 1.0) * 8388608.0 + 0.5
                    );

                if (mant_int >= 8388608) begin
                    mant_int = 0;
                    exp_val = exp_val + 1;
                end

                mant_bits = mant_int[22:0];

                biased_exp = exp_val + 127;
                exponent_bits = biased_exp[7:0];

                real_to_f32 = {
                    sign_bit,
                    exponent_bits,
                    mant_bits
                };
            end
        end
    endfunction


    // ============================================================
    // Internal real values
    // ============================================================
    real x_mm;
    real sin_val;
    real delay_value;


    // ============================================================
    // Delay calculation
    //
    // delay = x * sin(theta) / c
    //
    // x      : mm
    // sin    : dimensionless
    // c      : mm/us
    // delay  : us
    // ============================================================
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            delay_valid <= 1'b0;
            delay_us    <= 32'h00000000;
        end

        else begin

            delay_valid <= 1'b0;

            if (elem_valid && sin_valid) begin

                x_mm   = f32_to_real(elem_x);
                sin_val = f32_to_real(sin_theta);

                delay_value =
                    (x_mm * sin_val) / C_MM_US;

                delay_us <= real_to_f32(delay_value);

                delay_valid <= 1'b1;
            end
        end
    end

endmodule