//======================================================================
// SAG.v - Steering Angle Generator
//
// Parallel SIN/COS lookup for PAUT steering angles.
//
// theta_idx = 0 -> 40 degrees
// theta_idx = 1 -> 55 degrees
// theta_idx = 2 -> 70 degrees
//
// Architecture:
//   Stage 0 : angle request
//   Stage 1 : parallel SIN/COS LUT lookup + registered output
//
// Throughput : 1 angle / clock
// Latency    : 1 clock
//
// Outputs are IEEE-754 FLOAT32.
//======================================================================

`timescale 1ns/1ps

module SAG (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        angle_valid,
    input  wire [1:0]  theta_idx,

    output reg         trig_valid,
    output reg [31:0]  sin_theta,
    output reg [31:0]  cos_theta
);

    //==================================================================
    // Combinational parallel lookup
    //==================================================================

    reg [31:0] sin_next;
    reg [31:0] cos_next;

    always @(*) begin

        // Default values
        sin_next = 32'h00000000;
        cos_next = 32'h00000000;

        case (theta_idx)

            // 40 degrees
            2'd0: begin
                sin_next = 32'h3F248DBB;
                cos_next = 32'h3F441B7D;
            end

            // 55 degrees
            2'd1: begin
                sin_next = 32'h3F51B3F3;
                cos_next = 32'h3F12D0E5;
            end

            // 70 degrees
            2'd2: begin
                sin_next = 32'h3F708FB2;
                cos_next = 32'h3EAF1D44;
            end

            default: begin
                sin_next = 32'h00000000;
                cos_next = 32'h00000000;
            end

        endcase

    end


    //==================================================================
    // Pipeline Stage 1
    //
    // SIN and COS are registered simultaneously.
    // New angle can be accepted every clock.
    //==================================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            trig_valid <= 1'b0;
            sin_theta  <= 32'h00000000;
            cos_theta  <= 32'h00000000;

        end

        else begin

            trig_valid <= angle_valid;

            if (angle_valid) begin
                sin_theta <= sin_next;
                cos_theta <= cos_next;
            end

        end

    end

endmodule