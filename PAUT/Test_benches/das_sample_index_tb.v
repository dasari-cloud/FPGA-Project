`timescale 1ns / 1ps

module das_sample_index_tb;

    reg clk;
    reg rst_n;
    reg in_valid;

    reg [31:0] tof [0:31];

    wire sample_index_valid;
    wire [31:0] sample_index [0:31];

    integer i;
    integer error_count;


    // ============================================================
    // DUT
    // ============================================================

    das_sample_index dut (

        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),

        .tof_0(tof[0]),
        .tof_1(tof[1]),
        .tof_2(tof[2]),
        .tof_3(tof[3]),
        .tof_4(tof[4]),
        .tof_5(tof[5]),
        .tof_6(tof[6]),
        .tof_7(tof[7]),
        .tof_8(tof[8]),
        .tof_9(tof[9]),
        .tof_10(tof[10]),
        .tof_11(tof[11]),
        .tof_12(tof[12]),
        .tof_13(tof[13]),
        .tof_14(tof[14]),
        .tof_15(tof[15]),
        .tof_16(tof[16]),
        .tof_17(tof[17]),
        .tof_18(tof[18]),
        .tof_19(tof[19]),
        .tof_20(tof[20]),
        .tof_21(tof[21]),
        .tof_22(tof[22]),
        .tof_23(tof[23]),
        .tof_24(tof[24]),
        .tof_25(tof[25]),
        .tof_26(tof[26]),
        .tof_27(tof[27]),
        .tof_28(tof[28]),
        .tof_29(tof[29]),
        .tof_30(tof[30]),
        .tof_31(tof[31]),

        .sample_index_valid(sample_index_valid),

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
        .sample_index_31(sample_index[31])
    );


    // ============================================================
    // 100 MHz clock
    // ============================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // Input stimulus
    // Same TOFs from successful das_tof test
    // ============================================================

    initial begin

        rst_n       = 0;
        in_valid    = 0;
        error_count = 0;

        for (i = 0; i < 32; i = i + 1)
            tof[i] = 32'h00000000;

        repeat (10) @(posedge clk);

        rst_n = 1;

        repeat (5) @(posedge clk);


        // --------------------------------------------------------
        // Pixel:
        // x = 0 mm
        // z = 30 mm
        //
        // TX time = 40A33FBB
        //
        // These are the 32 verified total TOFs
        // --------------------------------------------------------

        @(negedge clk);

        tof[0]  = 32'h412123B6;
        tof[1]  = 32'h4120B3FB;
        tof[2]  = 32'h41204B23;
        tof[3]  = 32'h411FE94A;
        tof[4]  = 32'h411F8E8B;
        tof[5]  = 32'h411F3AFF;
        tof[6]  = 32'h411EEEBD;
        tof[7]  = 32'h411EA9DA;
        tof[8]  = 32'h411E6C6C;
        tof[9]  = 32'h411E3682;
        tof[10] = 32'h411E082E;
        tof[11] = 32'h411DE17D;
        tof[12] = 32'h411DC27B;
        tof[13] = 32'h411DAB31;
        tof[14] = 32'h411D9BA6;
        tof[15] = 32'h411D93E0;
        tof[16] = 32'h411D93E0;
        tof[17] = 32'h411D9BA6;
        tof[18] = 32'h411DAB31;
        tof[19] = 32'h411DC27B;
        tof[20] = 32'h411DE17D;
        tof[21] = 32'h411E082E;
        tof[22] = 32'h411E3682;
        tof[23] = 32'h411E6C6C;
        tof[24] = 32'h411EA9DA;
        tof[25] = 32'h411EEEBD;
        tof[26] = 32'h411F3AFF;
        tof[27] = 32'h411F8E8B;
        tof[28] = 32'h411FE94A;
        tof[29] = 32'h41204B23;
        tof[30] = 32'h4120B3FB;
        tof[31] = 32'h412123B6;

        in_valid = 1;

        @(negedge clk);
        in_valid = 0;


        $display("");
        $display("==========================================");
        $display("STANDARD DAS SAMPLE INDEX TEST");
        $display("Fs = 40 MHz");
        $display("NO UPSAMPLING");
        $display("NO INTERPOLATION");
        $display("==========================================");
        $display("");

        // Plenty of time for pipeline
        repeat (100) @(posedge clk);

        $display("");
        $display("ERROR: sample_index_valid never arrived.");
        $finish;

    end


    // ============================================================
    // Output verification
    // ============================================================

    always @(posedge clk) begin

        if (sample_index_valid) begin

            $display("");
            $display("==========================================");
            $display("SAMPLE INDICES VALID at time %0t", $time);
            $display("==========================================");

            for (i = 0; i < 32; i = i + 1) begin
                $display(
                    "RX%02d : index = %0d   hex = %08h",
                    i,
                    sample_index[i],
                    sample_index[i]
                );
            end


            // ----------------------------------------------------
            // Symmetry check
            // x = 0 pixel must be symmetric
            // ----------------------------------------------------

            for (i = 0; i < 16; i = i + 1) begin

                if (sample_index[i] !== sample_index[31-i]) begin

                    $display(
                        "ERROR: symmetry mismatch RX%0d / RX%0d : %0d != %0d",
                        i,
                        31-i,
                        sample_index[i],
                        sample_index[31-i]
                    );

                    error_count = error_count + 1;

                end

            end


            $display("");
            $display("------------------------------------------");

            if (error_count == 0) begin

                $display("RESULT: PASS");
                $display("All 32 sample indices generated.");
                $display("Symmetry check PASSED.");

            end
            else begin

                $display("RESULT: FAIL");
                $display("ERROR COUNT = %0d", error_count);

            end

            $display("------------------------------------------");
            $display("");

            $finish;

        end

    end

endmodule