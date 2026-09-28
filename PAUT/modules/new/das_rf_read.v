`timescale 1ns / 1ps

// ============================================================================
// DAS RF ADDRESS GENERATOR
//
// Y.hex layout:
//
//   Y[event][raw_channel][sample]
//
// 75 events
// 32 RX channels
// 1536 samples / RX channel
//
// Linear address:
//
//   address = event*49152 + raw_channel*1536 + sample_index
//
// IMPORTANT:
// Physical RX element order is reversed in raw RcvData:
//
//   physical RX0  -> raw channel31
//   physical RX1  -> raw channel30
//   ...
//   physical RX31 -> raw channel0
//
// Therefore:
//
//   raw_channel = 31 - physical_rx
//
// Standard DAS:
// NO interpolation
// NO upsampling
// ============================================================================

module das_rf_read (

    input wire clk,
    input wire rst_n,

    input wire       in_valid,
    input wire [6:0] event_idx,

    input wire [31:0] sample_index_0,
    input wire [31:0] sample_index_1,
    input wire [31:0] sample_index_2,
    input wire [31:0] sample_index_3,
    input wire [31:0] sample_index_4,
    input wire [31:0] sample_index_5,
    input wire [31:0] sample_index_6,
    input wire [31:0] sample_index_7,
    input wire [31:0] sample_index_8,
    input wire [31:0] sample_index_9,
    input wire [31:0] sample_index_10,
    input wire [31:0] sample_index_11,
    input wire [31:0] sample_index_12,
    input wire [31:0] sample_index_13,
    input wire [31:0] sample_index_14,
    input wire [31:0] sample_index_15,
    input wire [31:0] sample_index_16,
    input wire [31:0] sample_index_17,
    input wire [31:0] sample_index_18,
    input wire [31:0] sample_index_19,
    input wire [31:0] sample_index_20,
    input wire [31:0] sample_index_21,
    input wire [31:0] sample_index_22,
    input wire [31:0] sample_index_23,
    input wire [31:0] sample_index_24,
    input wire [31:0] sample_index_25,
    input wire [31:0] sample_index_26,
    input wire [31:0] sample_index_27,
    input wire [31:0] sample_index_28,
    input wire [31:0] sample_index_29,
    input wire [31:0] sample_index_30,
    input wire [31:0] sample_index_31,

    output reg        address_valid,

    output reg [21:0] rf_addr_0,
    output reg [21:0] rf_addr_1,
    output reg [21:0] rf_addr_2,
    output reg [21:0] rf_addr_3,
    output reg [21:0] rf_addr_4,
    output reg [21:0] rf_addr_5,
    output reg [21:0] rf_addr_6,
    output reg [21:0] rf_addr_7,
    output reg [21:0] rf_addr_8,
    output reg [21:0] rf_addr_9,
    output reg [21:0] rf_addr_10,
    output reg [21:0] rf_addr_11,
    output reg [21:0] rf_addr_12,
    output reg [21:0] rf_addr_13,
    output reg [21:0] rf_addr_14,
    output reg [21:0] rf_addr_15,
    output reg [21:0] rf_addr_16,
    output reg [21:0] rf_addr_17,
    output reg [21:0] rf_addr_18,
    output reg [21:0] rf_addr_19,
    output reg [21:0] rf_addr_20,
    output reg [21:0] rf_addr_21,
    output reg [21:0] rf_addr_22,
    output reg [21:0] rf_addr_23,
    output reg [21:0] rf_addr_24,
    output reg [21:0] rf_addr_25,
    output reg [21:0] rf_addr_26,
    output reg [21:0] rf_addr_27,
    output reg [21:0] rf_addr_28,
    output reg [21:0] rf_addr_29,
    output reg [21:0] rf_addr_30,
    output reg [21:0] rf_addr_31
);

    // ------------------------------------------------------------
    // Internal arrays
    // ------------------------------------------------------------

    wire [31:0] sample_index [0:31];
    reg  [21:0] rf_addr      [0:31];

    integer i;

    reg [21:0] event_base;
    reg [21:0] channel_base;


    // ------------------------------------------------------------
    // Input mapping
    // ------------------------------------------------------------

    assign sample_index[0]  = sample_index_0;
    assign sample_index[1]  = sample_index_1;
    assign sample_index[2]  = sample_index_2;
    assign sample_index[3]  = sample_index_3;
    assign sample_index[4]  = sample_index_4;
    assign sample_index[5]  = sample_index_5;
    assign sample_index[6]  = sample_index_6;
    assign sample_index[7]  = sample_index_7;
    assign sample_index[8]  = sample_index_8;
    assign sample_index[9]  = sample_index_9;
    assign sample_index[10] = sample_index_10;
    assign sample_index[11] = sample_index_11;
    assign sample_index[12] = sample_index_12;
    assign sample_index[13] = sample_index_13;
    assign sample_index[14] = sample_index_14;
    assign sample_index[15] = sample_index_15;
    assign sample_index[16] = sample_index_16;
    assign sample_index[17] = sample_index_17;
    assign sample_index[18] = sample_index_18;
    assign sample_index[19] = sample_index_19;
    assign sample_index[20] = sample_index_20;
    assign sample_index[21] = sample_index_21;
    assign sample_index[22] = sample_index_22;
    assign sample_index[23] = sample_index_23;
    assign sample_index[24] = sample_index_24;
    assign sample_index[25] = sample_index_25;
    assign sample_index[26] = sample_index_26;
    assign sample_index[27] = sample_index_27;
    assign sample_index[28] = sample_index_28;
    assign sample_index[29] = sample_index_29;
    assign sample_index[30] = sample_index_30;
    assign sample_index[31] = sample_index_31;


    // ------------------------------------------------------------
    // Address generation
    //
    // event size = 32 * 1536 = 49152
    //
    // raw_channel = 31 - physical_rx
    //
    // address =
    //
    // event*49152
    // + (31-rx)*1536
    // + sample_index
    //
    // One registered pipeline stage.
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin

            address_valid <= 1'b0;

            for (i = 0; i < 32; i = i + 1)
                rf_addr[i] <= 22'd0;

        end
        else begin

            address_valid <= in_valid;

            if (in_valid) begin

                for (i = 0; i < 32; i = i + 1) begin

                    if (sample_index[i] < 1536) begin

                        rf_addr[i] <=
                            (event_idx * 22'd49152)
                          + ((31-i) * 22'd1536)
                          + sample_index[i][21:0];

                    end
                    else begin

                        // Invalid sample index.
                        // Use zero address for now.
                        // Later we can also propagate a per-channel valid.
                        rf_addr[i] <= 22'd0;

                    end

                end

            end

        end

    end


    // ------------------------------------------------------------
    // Output mapping
    // ------------------------------------------------------------

    always @(*) begin

        rf_addr_0  = rf_addr[0];
        rf_addr_1  = rf_addr[1];
        rf_addr_2  = rf_addr[2];
        rf_addr_3  = rf_addr[3];
        rf_addr_4  = rf_addr[4];
        rf_addr_5  = rf_addr[5];
        rf_addr_6  = rf_addr[6];
        rf_addr_7  = rf_addr[7];
        rf_addr_8  = rf_addr[8];
        rf_addr_9  = rf_addr[9];
        rf_addr_10 = rf_addr[10];
        rf_addr_11 = rf_addr[11];
        rf_addr_12 = rf_addr[12];
        rf_addr_13 = rf_addr[13];
        rf_addr_14 = rf_addr[14];
        rf_addr_15 = rf_addr[15];
        rf_addr_16 = rf_addr[16];
        rf_addr_17 = rf_addr[17];
        rf_addr_18 = rf_addr[18];
        rf_addr_19 = rf_addr[19];
        rf_addr_20 = rf_addr[20];
        rf_addr_21 = rf_addr[21];
        rf_addr_22 = rf_addr[22];
        rf_addr_23 = rf_addr[23];
        rf_addr_24 = rf_addr[24];
        rf_addr_25 = rf_addr[25];
        rf_addr_26 = rf_addr[26];
        rf_addr_27 = rf_addr[27];
        rf_addr_28 = rf_addr[28];
        rf_addr_29 = rf_addr[29];
        rf_addr_30 = rf_addr[30];
        rf_addr_31 = rf_addr[31];

    end

endmodule