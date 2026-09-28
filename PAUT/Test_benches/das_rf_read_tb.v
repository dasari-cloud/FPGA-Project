`timescale 1ns / 1ps

module das_rf_read_tb;

    localparam TOTAL_RF_SAMPLES = 3686400;

    reg clk;
    reg rst_n;
    reg in_valid;

    reg [6:0] event_idx;

    reg [31:0] sample_index [0:31];

    wire address_valid;
    wire [21:0] rf_addr [0:31];

    // Complete one-frame RF memory
    reg signed [15:0] rf_mem [0:TOTAL_RF_SAMPLES-1];

    reg signed [15:0] rf_sample [0:31];

    integer i;


    // ============================================================
    // DUT
    // ============================================================

    das_rf_read dut (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(in_valid),
        .event_idx(event_idx),

        .sample_index_0(sample_index[0]),
        .sample_index_1(sample_index[1]),
        .sample_index_2(sample_index[2]),
        .sample_index_3(sample_index[3]),
        .sample_index_4(sample_index[4]),
        .sample_index_5(sample_index[5]),
        .sample_index_6(sample_index[6]),
        .sample_index_7(sample_index[7]),
        .sample_index_8(sample_index[8]),
        .sample_index_9(sample_index[9]),
        .sample_index_10(sample_index[10]),
        .sample_index_11(sample_index[11]),
        .sample_index_12(sample_index[12]),
        .sample_index_13(sample_index[13]),
        .sample_index_14(sample_index[14]),
        .sample_index_15(sample_index[15]),
        .sample_index_16(sample_index[16]),
        .sample_index_17(sample_index[17]),
        .sample_index_18(sample_index[18]),
        .sample_index_19(sample_index[19]),
        .sample_index_20(sample_index[20]),
        .sample_index_21(sample_index[21]),
        .sample_index_22(sample_index[22]),
        .sample_index_23(sample_index[23]),
        .sample_index_24(sample_index[24]),
        .sample_index_25(sample_index[25]),
        .sample_index_26(sample_index[26]),
        .sample_index_27(sample_index[27]),
        .sample_index_28(sample_index[28]),
        .sample_index_29(sample_index[29]),
        .sample_index_30(sample_index[30]),
        .sample_index_31(sample_index[31]),

        .address_valid(address_valid),

        .rf_addr_0(rf_addr[0]),
        .rf_addr_1(rf_addr[1]),
        .rf_addr_2(rf_addr[2]),
        .rf_addr_3(rf_addr[3]),
        .rf_addr_4(rf_addr[4]),
        .rf_addr_5(rf_addr[5]),
        .rf_addr_6(rf_addr[6]),
        .rf_addr_7(rf_addr[7]),
        .rf_addr_8(rf_addr[8]),
        .rf_addr_9(rf_addr[9]),
        .rf_addr_10(rf_addr[10]),
        .rf_addr_11(rf_addr[11]),
        .rf_addr_12(rf_addr[12]),
        .rf_addr_13(rf_addr[13]),
        .rf_addr_14(rf_addr[14]),
        .rf_addr_15(rf_addr[15]),
        .rf_addr_16(rf_addr[16]),
        .rf_addr_17(rf_addr[17]),
        .rf_addr_18(rf_addr[18]),
        .rf_addr_19(rf_addr[19]),
        .rf_addr_20(rf_addr[20]),
        .rf_addr_21(rf_addr[21]),
        .rf_addr_22(rf_addr[22]),
        .rf_addr_23(rf_addr[23]),
        .rf_addr_24(rf_addr[24]),
        .rf_addr_25(rf_addr[25]),
        .rf_addr_26(rf_addr[26]),
        .rf_addr_27(rf_addr[27]),
        .rf_addr_28(rf_addr[28]),
        .rf_addr_29(rf_addr[29]),
        .rf_addr_30(rf_addr[30]),
        .rf_addr_31(rf_addr[31])
    );


    // ============================================================
    // Clock = 100 MHz
    // ============================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // Load complete frame
    // ============================================================

    initial begin

        $display("");
        $display("Loading Y.hex ...");

        $readmemh("D:/Users/Nagendra/PAUT_FPGA/FPGA-Project/PAUT/Y.hex", rf_mem);

        $display("Y.hex loaded.");
        $display("");

    end


    // ============================================================
    // Stimulus
    // ============================================================

    initial begin

        rst_n     = 0;
        in_valid  = 0;
        event_idx = 0;

        for (i = 0; i < 32; i = i + 1)
            sample_index[i] = 0;

        repeat (10) @(posedge clk);

        rst_n = 1;

        repeat (5) @(posedge clk);


        // --------------------------------------------------------
        // Same sample indices from our verified sample-index stage
        // --------------------------------------------------------

        @(negedge clk);

        event_idx = 7'd0;

        sample_index[0]  = 403;
        sample_index[1]  = 402;
        sample_index[2]  = 401;
        sample_index[3]  = 400;
        sample_index[4]  = 399;
        sample_index[5]  = 398;
        sample_index[6]  = 397;
        sample_index[7]  = 397;

        sample_index[8]  = 396;
        sample_index[9]  = 396;
        sample_index[10] = 395;
        sample_index[11] = 395;
        sample_index[12] = 394;
        sample_index[13] = 394;
        sample_index[14] = 394;
        sample_index[15] = 394;

        sample_index[16] = 394;
        sample_index[17] = 394;
        sample_index[18] = 394;
        sample_index[19] = 394;
        sample_index[20] = 395;
        sample_index[21] = 395;
        sample_index[22] = 396;
        sample_index[23] = 396;

        sample_index[24] = 397;
        sample_index[25] = 397;
        sample_index[26] = 398;
        sample_index[27] = 399;
        sample_index[28] = 400;
        sample_index[29] = 401;
        sample_index[30] = 402;
        sample_index[31] = 403;

        in_valid = 1;

        @(negedge clk);

        in_valid = 0;


        $display("");
        $display("============================================");
        $display("DAS RF READ TEST");
        $display("Event = 0");
        $display("============================================");
        $display("");


        repeat (20) @(posedge clk);

        $display("ERROR: address_valid never arrived.");
        $finish;

    end


    // ============================================================
    // Read Y.hex using generated addresses
    // ============================================================

    always @(posedge clk) begin

        if (address_valid) begin

            $display("");
            $display("============================================");
            $display("RF ADDRESSES + SAMPLES at time %0t", $time);
            $display("============================================");

            for (i = 0; i < 32; i = i + 1) begin

                rf_sample[i] = rf_mem[rf_addr[i]];

                $display(
                    "RX%02d : addr=%0d   sample_index=%0d   RF=%0d   hex=%04h",
                    i,
                    rf_addr[i],
                    sample_index[i],
                    $signed(rf_mem[rf_addr[i]]),
                    rf_mem[rf_addr[i]]
                );

            end

            $display("");
            $display("RF READ COMPLETE.");
            $display("");

            $finish;

        end

    end

endmodule