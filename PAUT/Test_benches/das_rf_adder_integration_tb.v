`timescale 1ns / 1ps

module das_rf_adder_integration_tb;

    // ============================================================
    // Parameters
    // ============================================================

    localparam TOTAL_RF_SAMPLES = 3686400;

    // ============================================================
    // Clock / Reset
    // ============================================================

    reg clk;
    reg rst_n;

    // ============================================================
    // RF address generator inputs
    // ============================================================

    reg        in_valid;
    reg [6:0]  event_idx;

    reg [31:0] sample_index [0:31];

    // ============================================================
    // RF addresses
    // ============================================================

    wire       address_valid;
    wire [21:0] rf_addr [0:31];

    // ============================================================
    // RF memory
    // ============================================================

    reg signed [15:0] rf_mem [0:TOTAL_RF_SAMPLES-1];

    // Samples going into adder tree
    reg signed [15:0] rf_sample [0:31];

    reg adder_in_valid;

    // ============================================================
    // Adder output
    // ============================================================

    wire signed [20:0] das_sum;
    wire               das_valid;

    integer i;


    // ============================================================
    // CLOCK
    // 100 MHz
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // RF ADDRESS GENERATOR
    // ============================================================

    das_rf_read rf_reader (

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
    // 32-CHANNEL ADDER TREE
    // ============================================================

    das_adder_tree adder (

        .clk(clk),
        .rst_n(rst_n),
        .in_valid(adder_in_valid),

        .rf_0(rf_sample[0]),
        .rf_1(rf_sample[1]),
        .rf_2(rf_sample[2]),
        .rf_3(rf_sample[3]),
        .rf_4(rf_sample[4]),
        .rf_5(rf_sample[5]),
        .rf_6(rf_sample[6]),
        .rf_7(rf_sample[7]),
        .rf_8(rf_sample[8]),
        .rf_9(rf_sample[9]),
        .rf_10(rf_sample[10]),
        .rf_11(rf_sample[11]),
        .rf_12(rf_sample[12]),
        .rf_13(rf_sample[13]),
        .rf_14(rf_sample[14]),
        .rf_15(rf_sample[15]),
        .rf_16(rf_sample[16]),
        .rf_17(rf_sample[17]),
        .rf_18(rf_sample[18]),
        .rf_19(rf_sample[19]),
        .rf_20(rf_sample[20]),
        .rf_21(rf_sample[21]),
        .rf_22(rf_sample[22]),
        .rf_23(rf_sample[23]),
        .rf_24(rf_sample[24]),
        .rf_25(rf_sample[25]),
        .rf_26(rf_sample[26]),
        .rf_27(rf_sample[27]),
        .rf_28(rf_sample[28]),
        .rf_29(rf_sample[29]),
        .rf_30(rf_sample[30]),
        .rf_31(rf_sample[31]),

        .das_sum(das_sum),
        .das_valid(das_valid)
    );


    // ============================================================
    // LOAD Y.hex
    // ============================================================

    initial begin

        $display("");
        $display("Loading Y.hex ...");

        $readmemh(
            "D:/Users/Nagendra/PAUT_FPGA/FPGA-Project/PAUT/Y.hex",
            rf_mem
        );

        $display("Y.hex loaded.");
        $display("");

    end


    // ============================================================
    // READ RF MEMORY
    //
    // address_valid means rf_addr[0:31] are valid.
    // We read the corresponding Y.hex samples and present them
    // to the adder tree.
    // ============================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            adder_in_valid <= 1'b0;

            for (i = 0; i < 32; i = i + 1)
                rf_sample[i] <= 16'sd0;

        end
        else begin

            adder_in_valid <= address_valid;

            if (address_valid) begin

                rf_sample[0]  <= rf_mem[rf_addr[0]];
                rf_sample[1]  <= rf_mem[rf_addr[1]];
                rf_sample[2]  <= rf_mem[rf_addr[2]];
                rf_sample[3]  <= rf_mem[rf_addr[3]];
                rf_sample[4]  <= rf_mem[rf_addr[4]];
                rf_sample[5]  <= rf_mem[rf_addr[5]];
                rf_sample[6]  <= rf_mem[rf_addr[6]];
                rf_sample[7]  <= rf_mem[rf_addr[7]];
                rf_sample[8]  <= rf_mem[rf_addr[8]];
                rf_sample[9]  <= rf_mem[rf_addr[9]];
                rf_sample[10] <= rf_mem[rf_addr[10]];
                rf_sample[11] <= rf_mem[rf_addr[11]];
                rf_sample[12] <= rf_mem[rf_addr[12]];
                rf_sample[13] <= rf_mem[rf_addr[13]];
                rf_sample[14] <= rf_mem[rf_addr[14]];
                rf_sample[15] <= rf_mem[rf_addr[15]];
                rf_sample[16] <= rf_mem[rf_addr[16]];
                rf_sample[17] <= rf_mem[rf_addr[17]];
                rf_sample[18] <= rf_mem[rf_addr[18]];
                rf_sample[19] <= rf_mem[rf_addr[19]];
                rf_sample[20] <= rf_mem[rf_addr[20]];
                rf_sample[21] <= rf_mem[rf_addr[21]];
                rf_sample[22] <= rf_mem[rf_addr[22]];
                rf_sample[23] <= rf_mem[rf_addr[23]];
                rf_sample[24] <= rf_mem[rf_addr[24]];
                rf_sample[25] <= rf_mem[rf_addr[25]];
                rf_sample[26] <= rf_mem[rf_addr[26]];
                rf_sample[27] <= rf_mem[rf_addr[27]];
                rf_sample[28] <= rf_mem[rf_addr[28]];
                rf_sample[29] <= rf_mem[rf_addr[29]];
                rf_sample[30] <= rf_mem[rf_addr[30]];
                rf_sample[31] <= rf_mem[rf_addr[31]];

            end

        end

    end


    // ============================================================
    // TEST
    // ============================================================

    initial begin

        rst_n          = 1'b0;
        in_valid       = 1'b0;
        event_idx      = 7'd0;
        adder_in_valid = 1'b0;

        for (i = 0; i < 32; i = i + 1)
            sample_index[i] = 32'd0;


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (10) @(posedge clk);

        rst_n = 1'b1;

        repeat (5) @(posedge clk);


        // --------------------------------------------------------
        // Verified sample indices
        // Event 0, x = 0 mm, z = 30 mm
        // --------------------------------------------------------

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

        event_idx = 7'd0;


        // --------------------------------------------------------
        // Send one request
        // --------------------------------------------------------

        @(negedge clk);

        in_valid = 1'b1;

        $display("============================================");
        $display("RF READ + ADDER INTEGRATION TEST");
        $display("============================================");
        $display("Event        = 0");
        $display("Pixel        = x=0 mm, z=30 mm");
        $display("Expected sum = -340");
        $display("");


        @(negedge clk);

        in_valid = 1'b0;


        // --------------------------------------------------------
        // Wait
        // --------------------------------------------------------

        repeat (30) @(posedge clk);

        $display("");
        $display("ERROR: DAS output never arrived.");
        $finish;

    end


    // ============================================================
    // DEBUG: Show actual RF values going into adder
    // ============================================================

    always @(posedge clk) begin

        if (adder_in_valid) begin

            $display("");
            $display("============================================");
            $display("RF SAMPLES SENT TO ADDER at %0t", $time);
            $display("============================================");

            for (i = 0; i < 32; i = i + 1) begin

                $display(
                    "RX%02d : addr=%0d  sample_index=%0d  RF=%0d",
                    i,
                    rf_addr[i],
                    sample_index[i],
                    $signed(rf_sample[i])
                );

            end

        end

    end


    // ============================================================
    // FINAL OUTPUT CHECK
    // ============================================================

    always @(posedge clk) begin

        if (das_valid) begin

            $display("");
            $display("============================================");
            $display("FINAL DAS EVENT OUTPUT at %0t", $time);
            $display("============================================");

            $display(
                "DAS SUM = %0d",
                $signed(das_sum)
            );

            $display("");

            if ($signed(das_sum) == -340) begin

                $display("RESULT: PASS");
                $display("Expected = -340");
                $display("Actual   = %0d", $signed(das_sum));

            end
            else begin

                $display("RESULT: FAIL");
                $display("Expected = -340");
                $display("Actual   = %0d", $signed(das_sum));

            end

            $display("============================================");
            $display("");

            $finish;

        end

    end

endmodule