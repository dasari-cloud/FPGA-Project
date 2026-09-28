`timescale 1ns / 1ps

module das_adder_tree (

    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,

    input wire signed [15:0] rf_0,
    input wire signed [15:0] rf_1,
    input wire signed [15:0] rf_2,
    input wire signed [15:0] rf_3,
    input wire signed [15:0] rf_4,
    input wire signed [15:0] rf_5,
    input wire signed [15:0] rf_6,
    input wire signed [15:0] rf_7,
    input wire signed [15:0] rf_8,
    input wire signed [15:0] rf_9,
    input wire signed [15:0] rf_10,
    input wire signed [15:0] rf_11,
    input wire signed [15:0] rf_12,
    input wire signed [15:0] rf_13,
    input wire signed [15:0] rf_14,
    input wire signed [15:0] rf_15,
    input wire signed [15:0] rf_16,
    input wire signed [15:0] rf_17,
    input wire signed [15:0] rf_18,
    input wire signed [15:0] rf_19,
    input wire signed [15:0] rf_20,
    input wire signed [15:0] rf_21,
    input wire signed [15:0] rf_22,
    input wire signed [15:0] rf_23,
    input wire signed [15:0] rf_24,
    input wire signed [15:0] rf_25,
    input wire signed [15:0] rf_26,
    input wire signed [15:0] rf_27,
    input wire signed [15:0] rf_28,
    input wire signed [15:0] rf_29,
    input wire signed [15:0] rf_30,
    input wire signed [15:0] rf_31,

    output reg signed [20:0] das_sum,
    output reg               das_valid
);

    // ============================================================
    // Stage 1
    // 32 x 16-bit -> 16 x 17-bit
    // ============================================================

    reg signed [16:0] s1 [0:15];

    // ============================================================
    // Stage 2
    // 16 x 17-bit -> 8 x 18-bit
    // ============================================================

    reg signed [17:0] s2 [0:7];

    // ============================================================
    // Stage 3
    // 8 x 18-bit -> 4 x 19-bit
    // ============================================================

    reg signed [18:0] s3 [0:3];

    // ============================================================
    // Stage 4
    // 4 x 19-bit -> 2 x 20-bit
    // ============================================================

    reg signed [19:0] s4 [0:1];

    // ============================================================
    // Valid pipeline
    // ============================================================

    reg valid_s1;
    reg valid_s2;
    reg valid_s3;
    reg valid_s4;
    //reg valid_s5;


    always @(posedge clk) begin

        if (!rst_n) begin

            valid_s1 <= 1'b0;
            valid_s2 <= 1'b0;
            valid_s3 <= 1'b0;
            valid_s4 <= 1'b0;
            //valid_s5 <= 1'b0;

            das_valid <= 1'b0;
            das_sum   <= 21'sd0;

            s1[0]  <= 17'sd0;
            s1[1]  <= 17'sd0;
            s1[2]  <= 17'sd0;
            s1[3]  <= 17'sd0;
            s1[4]  <= 17'sd0;
            s1[5]  <= 17'sd0;
            s1[6]  <= 17'sd0;
            s1[7]  <= 17'sd0;
            s1[8]  <= 17'sd0;
            s1[9]  <= 17'sd0;
            s1[10] <= 17'sd0;
            s1[11] <= 17'sd0;
            s1[12] <= 17'sd0;
            s1[13] <= 17'sd0;
            s1[14] <= 17'sd0;
            s1[15] <= 17'sd0;

            s2[0] <= 18'sd0;
            s2[1] <= 18'sd0;
            s2[2] <= 18'sd0;
            s2[3] <= 18'sd0;
            s2[4] <= 18'sd0;
            s2[5] <= 18'sd0;
            s2[6] <= 18'sd0;
            s2[7] <= 18'sd0;

            s3[0] <= 19'sd0;
            s3[1] <= 19'sd0;
            s3[2] <= 19'sd0;
            s3[3] <= 19'sd0;

            s4[0] <= 20'sd0;
            s4[1] <= 20'sd0;

        end
        else begin

            // ----------------------------------------------------
            // Valid pipeline
            // ----------------------------------------------------

            valid_s1 <= in_valid;
            valid_s2 <= valid_s1;
            valid_s3 <= valid_s2;
            valid_s4 <= valid_s3;

            das_valid <= valid_s4;


            // ----------------------------------------------------
            // STAGE 1
            // Sign extend before addition
            // ----------------------------------------------------

            if (in_valid) begin

                s1[0]  <= $signed({rf_0[15],  rf_0})  +
                          $signed({rf_1[15],  rf_1});

                s1[1]  <= $signed({rf_2[15],  rf_2})  +
                          $signed({rf_3[15],  rf_3});

                s1[2]  <= $signed({rf_4[15],  rf_4})  +
                          $signed({rf_5[15],  rf_5});

                s1[3]  <= $signed({rf_6[15],  rf_6})  +
                          $signed({rf_7[15],  rf_7});

                s1[4]  <= $signed({rf_8[15],  rf_8})  +
                          $signed({rf_9[15],  rf_9});

                s1[5]  <= $signed({rf_10[15], rf_10}) +
                          $signed({rf_11[15], rf_11});

                s1[6]  <= $signed({rf_12[15], rf_12}) +
                          $signed({rf_13[15], rf_13});

                s1[7]  <= $signed({rf_14[15], rf_14}) +
                          $signed({rf_15[15], rf_15});

                s1[8]  <= $signed({rf_16[15], rf_16}) +
                          $signed({rf_17[15], rf_17});

                s1[9]  <= $signed({rf_18[15], rf_18}) +
                          $signed({rf_19[15], rf_19});

                s1[10] <= $signed({rf_20[15], rf_20}) +
                          $signed({rf_21[15], rf_21});

                s1[11] <= $signed({rf_22[15], rf_22}) +
                          $signed({rf_23[15], rf_23});

                s1[12] <= $signed({rf_24[15], rf_24}) +
                          $signed({rf_25[15], rf_25});

                s1[13] <= $signed({rf_26[15], rf_26}) +
                          $signed({rf_27[15], rf_27});

                s1[14] <= $signed({rf_28[15], rf_28}) +
                          $signed({rf_29[15], rf_29});

                s1[15] <= $signed({rf_30[15], rf_30}) +
                          $signed({rf_31[15], rf_31});

            end


            // ----------------------------------------------------
            // STAGE 2
            // ----------------------------------------------------

            if (valid_s1) begin

                s2[0] <= $signed({s1[0][16], s1[0]}) +
                         $signed({s1[1][16], s1[1]});

                s2[1] <= $signed({s1[2][16], s1[2]}) +
                         $signed({s1[3][16], s1[3]});

                s2[2] <= $signed({s1[4][16], s1[4]}) +
                         $signed({s1[5][16], s1[5]});

                s2[3] <= $signed({s1[6][16], s1[6]}) +
                         $signed({s1[7][16], s1[7]});

                s2[4] <= $signed({s1[8][16], s1[8]}) +
                         $signed({s1[9][16], s1[9]});

                s2[5] <= $signed({s1[10][16], s1[10]}) +
                         $signed({s1[11][16], s1[11]});

                s2[6] <= $signed({s1[12][16], s1[12]}) +
                         $signed({s1[13][16], s1[13]});

                s2[7] <= $signed({s1[14][16], s1[14]}) +
                         $signed({s1[15][16], s1[15]});

            end


            // ----------------------------------------------------
            // STAGE 3
            // ----------------------------------------------------

            if (valid_s2) begin

                s3[0] <= $signed({s2[0][17], s2[0]}) +
                         $signed({s2[1][17], s2[1]});

                s3[1] <= $signed({s2[2][17], s2[2]}) +
                         $signed({s2[3][17], s2[3]});

                s3[2] <= $signed({s2[4][17], s2[4]}) +
                         $signed({s2[5][17], s2[5]});

                s3[3] <= $signed({s2[6][17], s2[6]}) +
                         $signed({s2[7][17], s2[7]});

            end


            // ----------------------------------------------------
            // STAGE 4
            // ----------------------------------------------------

            if (valid_s3) begin

                s4[0] <= $signed({s3[0][18], s3[0]}) +
                         $signed({s3[1][18], s3[1]});

                s4[1] <= $signed({s3[2][18], s3[2]}) +
                         $signed({s3[3][18], s3[3]});

            end


            // ----------------------------------------------------
            // STAGE 5
            // Final 21-bit DAS sum
            // ----------------------------------------------------

            if (valid_s4) begin

                das_sum <=
                    $signed({s4[0][19], s4[0]}) +
                    $signed({s4[1][19], s4[1]});

            end

        end

    end

endmodule