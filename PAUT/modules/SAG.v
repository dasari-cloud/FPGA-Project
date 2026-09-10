//======================================================================
// SAG.v - Steering Angle Generator
//
// Steering angle range : -70° to +70°
// Angle step            : 1°
// Number of angles      : 141
//
// theta_idx:
//     0   -> -70°
//     70  ->   0°
//     140 -> +70°
//
// Output:
//     sin_theta -> IEEE-754 FLOAT32
//
// This block only generates sin(theta).
// Delay calculation is handled by the next block.
//======================================================================

`timescale 1ns/1ps

module SAG #(
    parameter MIN_ANGLE = -70,
    parameter MAX_ANGLE =  70
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        angle_valid,
    input  wire [7:0]  theta_idx,

    output reg         sin_valid,
    output reg [31:0]  sin_theta
);

function [31:0] real_to_f32;
    input real val;

    integer exp_val;
    integer biased_exp;
    integer mant_int;

    real mag;

    reg        sign_bit;
    reg [7:0]  exponent_bits;
    reg [22:0] mant_bits;

    begin

        // ----------------------------------------------------------
        // Zero
        // ----------------------------------------------------------

        if (val == 0.0) begin

            real_to_f32 = 32'h00000000;

        end

        else begin

            // ------------------------------------------------------
            // Sign
            // ------------------------------------------------------

            if (val < 0.0) begin
                sign_bit = 1'b1;
                mag = -val;
            end
            else begin
                sign_bit = 1'b0;
                mag = val;
            end


            // ------------------------------------------------------
            // Normalize:
            //
            //     1.xxxxx × 2^exp
            // ------------------------------------------------------

            exp_val = 0;

            while (mag >= 2.0) begin
                mag = mag / 2.0;
                exp_val = exp_val + 1;
            end

            while (mag < 1.0) begin
                mag = mag * 2.0;
                exp_val = exp_val - 1;
            end


            // ------------------------------------------------------
            // Mantissa
            //
            // Remove the implicit leading 1.
            // Store remaining 23 bits.
            // ------------------------------------------------------

            mant_int = $rtoi(
                (mag - 1.0) * 8388608.0 + 0.5
            );


            // ------------------------------------------------------
            // Handle rounding overflow
            // ------------------------------------------------------

            if (mant_int >= 8388608) begin

                mant_int = 0;
                exp_val = exp_val + 1;

            end


            mant_bits = mant_int[22:0];


            // ------------------------------------------------------
            // IEEE-754 exponent
            // ------------------------------------------------------

            biased_exp = exp_val + 127;

            exponent_bits = biased_exp[7:0];


            // ------------------------------------------------------
            // FLOAT32
            //
            // [31]    Sign
            // [30:23] Exponent
            // [22:0]  Mantissa
            // ------------------------------------------------------

            real_to_f32 = {
                sign_bit,
                exponent_bits,
                mant_bits
            };

        end

    end

endfunction


    // --------------------------------------------------------------
    // Sine LUT
    // --------------------------------------------------------------

    reg [31:0] sin_rom [0:140];

    integer k;
    real angle_rad;

    initial begin

        for (k = 0; k <= 140; k = k + 1) begin

            // theta = -70 + k degrees
            angle_rad =
                (-70.0 + k) * 3.141592653589793 / 180.0;

            sin_rom[k] =
                real_to_f32($sin(angle_rad));

        end

    end


    // --------------------------------------------------------------
    // Output register
    // One clock latency
    // --------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            sin_valid <= 1'b0;
            sin_theta <= 32'h00000000;

        end

        else begin

            sin_valid <= angle_valid;

            if (angle_valid) begin

                sin_theta <= sin_rom[theta_idx];

            end

        end

    end

endmodule