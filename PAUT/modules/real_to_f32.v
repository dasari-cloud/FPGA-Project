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

        // =====================================================
        // ZERO
        // =====================================================
        if (val == 0.0) begin

            real_to_f32 = 32'h00000000;

        end
        else begin

            // =================================================
            // SIGN
            // =================================================
            if (val < 0.0) begin
                sign_bit = 1'b1;
                mag = -val;
            end
            else begin
                sign_bit = 1'b0;
                mag = val;
            end

            // =================================================
            // NORMALIZE
            //
            // Want:
            //
            //       1.0 <= mag < 2.0
            //
            // =================================================
            exp_val = 0;

            while (mag >= 2.0) begin
                mag = mag / 2.0;
                exp_val = exp_val + 1;
            end

            while (mag < 1.0) begin
                mag = mag * 2.0;
                exp_val = exp_val - 1;
            end

            // =================================================
            // IMPORTANT:
            //
            // Fix floating-point boundary error.
            //
            // Example:
            //
            // sin(30) ≈ 0.49999999999999994
            //
            // after normalization it may become
            //
            // 1.9999999999999998
            //
            // which incorrectly gives exponent -2.
            //
            // Detect values close to 1 or 2.
            // =================================================

            if ((mag - 1.0 < EPS) &&
                (1.0 - mag < EPS)) begin

                mag = 1.0;
                exp_val = exp_val + 1;

            end
            else if ((mag - 2.0 < EPS) &&
                     (2.0 - mag < EPS)) begin

                mag = 1.0;
                exp_val = exp_val + 1;

            end

            // =================================================
            // MANTISSA
            // =================================================

            mant_int =
                $rtoi(
                    (mag - 1.0) * 8388608.0 + 0.5
                );

            // =================================================
            // MANTISSA ROUNDING OVERFLOW
            // =================================================

            if (mant_int >= 8388608) begin

                mant_int = 0;
                exp_val = exp_val + 1;

            end

            mant_bits = mant_int[22:0];

            // =================================================
            // EXPONENT
            // =================================================

            biased_exp = exp_val + 127;

            exponent_bits = biased_exp[7:0];

            // =================================================
            // IEEE-754 FLOAT32
            //
            // sign | exponent | mantissa
            //  1   |    8     |    23
            // =================================================

            real_to_f32 = {
                sign_bit,
                exponent_bits,
                mant_bits
            };

        end

    end
endfunction