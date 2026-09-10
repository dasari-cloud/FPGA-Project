
// EEP.v - Element Position Generator
//
// 64-element linear array
// Pitch = 0.5 mm
// Center 32 active elements = E16 ... E47
//
// Output:
//   elem_x = element X position in IEEE-754 float32, mm
//   elem_z = 0.0 (linear array)
//======================================================================

module EEP #(
    parameter integer N = 64,
    parameter real    PITCH_MM = 0.5
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        elem_valid,
    input  wire [5:0]  elem_idx,

    output reg         pos_valid,
    output reg [31:0]  elem_x,
    output reg [31:0]  elem_z
);

//==============================================================
// REAL -> IEEE-754 FLOAT32
// Used only when building the ROM during elaboration/simulation.
// NOT runtime floating-point hardware.
//==============================================================

function [31:0] real_to_f32;
    input real val;

    integer exp_val;
    integer biased_exp;

    real mag;

    reg        sign_bit;
    reg [7:0]  exponent_bits;
    reg [22:0] mant_bits;

    begin

        // Zero
        if (val == 0.0) begin

            real_to_f32 = 32'h00000000;

        end

        else begin

            // --------------------------------------------------
            // Sign
            // --------------------------------------------------

            if (val < 0.0)
                sign_bit = 1'b1;
            else
                sign_bit = 1'b0;

            // Absolute value
            if (val < 0.0)
                mag = -val;
            else
                mag = val;

            // --------------------------------------------------
            // Normalize:
            //
            //     1.xxxxx * 2^exp
            // --------------------------------------------------

            exp_val = 0;

            while (mag >= 2.0) begin
                mag = mag / 2.0;
                exp_val = exp_val + 1;
            end

            while (mag < 1.0) begin
                mag = mag * 2.0;
                exp_val = exp_val - 1;
            end

            // --------------------------------------------------
            // Mantissa
            // --------------------------------------------------

            mant_bits =
                $rtoi(
                    (mag - 1.0) * 8388608.0 + 0.5
                );

            // --------------------------------------------------
            // IEEE-754 exponent
            // --------------------------------------------------

            biased_exp = exp_val + 127;

            exponent_bits = biased_exp[7:0];

            // --------------------------------------------------
            // Construct IEEE-754:
            //
            // [31]    Sign
            // [30:23] Exponent
            // [22:0]  Mantissa
            // --------------------------------------------------

            real_to_f32 = {
                sign_bit,
                exponent_bits,
                mant_bits
            };

        end

    end

endfunction


    //==============================================================
    // ELEMENT POSITION ROM
    //==============================================================

    reg [31:0] x_rom [0:N-1];

    integer k;

    // Center of 64-element array
    //
    // (64 - 1) / 2 = 31.5
    //
    // Therefore:
    //
    // E31 = -0.25 mm
    // E32 = +0.25 mm
    //==============================================================

    initial begin

        for (k = 0; k < N; k = k + 1) begin

            x_rom[k] =
                real_to_f32(
                    (k - 31.5) * PITCH_MM
                );

        end

    end


    //==============================================================
    // SYNCHRONOUS POSITION LOOKUP
    //==============================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            pos_valid <= 1'b0;
            elem_x    <= 32'h00000000;
            elem_z    <= 32'h00000000;

        end

        else begin

            pos_valid <= elem_valid;

            if (elem_valid) begin

                elem_x <= x_rom[elem_idx];

                // Linear array:
                // all elements are at Z = 0
                elem_z <= 32'h00000000;

            end

        end

    end

endmodule