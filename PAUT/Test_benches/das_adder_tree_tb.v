`timescale 1ns / 1ps

module das_adder_tree_tb;

    reg clk;
    reg rst_n;
    reg in_valid;

    reg signed [15:0] rf [0:31];

    wire signed [20:0] das_sum;
    wire das_valid;

    integer i;
    integer output_count;
    integer error_count;
    integer last_output_time;


    // ============================================================
    // DUT
    // ============================================================

    das_adder_tree dut (

        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),

        .rf_0(rf[0]),
        .rf_1(rf[1]),
        .rf_2(rf[2]),
        .rf_3(rf[3]),
        .rf_4(rf[4]),
        .rf_5(rf[5]),
        .rf_6(rf[6]),
        .rf_7(rf[7]),
        .rf_8(rf[8]),
        .rf_9(rf[9]),
        .rf_10(rf[10]),
        .rf_11(rf[11]),
        .rf_12(rf[12]),
        .rf_13(rf[13]),
        .rf_14(rf[14]),
        .rf_15(rf[15]),
        .rf_16(rf[16]),
        .rf_17(rf[17]),
        .rf_18(rf[18]),
        .rf_19(rf[19]),
        .rf_20(rf[20]),
        .rf_21(rf[21]),
        .rf_22(rf[22]),
        .rf_23(rf[23]),
        .rf_24(rf[24]),
        .rf_25(rf[25]),
        .rf_26(rf[26]),
        .rf_27(rf[27]),
        .rf_28(rf[28]),
        .rf_29(rf[29]),
        .rf_30(rf[30]),
        .rf_31(rf[31]),

        .das_sum(das_sum),
        .das_valid(das_valid)
    );


    // ============================================================
    // 100 MHz clock
    // ============================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // Stimulus
    // ============================================================

    initial begin

        rst_n = 0;
        in_valid = 0;

        output_count = 0;
        error_count = 0;
        last_output_time = 0;

        for (i = 0; i < 32; i = i + 1)
            rf[i] = 0;

        repeat (10) @(posedge clk);

        rst_n = 1;

        repeat (5) @(posedge clk);


        $display("");
        $display("============================================");
        $display("DAS ADDER TREE BACK-TO-BACK II=1 TEST");
        $display("============================================");
        $display("");


        // ========================================================
        // SET A
        //
        // Same actual RF samples from Y.hex
        //
        // Expected = -340
        // ========================================================

        @(negedge clk);

        for (i = 0; i < 32; i = i + 1)
            rf[i] = 0;

        rf[28] = -16'sd5;
        rf[29] = -16'sd139;
        rf[30] =  16'sd403;
        rf[31] = -16'sd599;

        in_valid = 1;

        $display(
            "INPUT A at %0t : expected = -340",
            $time
        );


        // ========================================================
        // SET B
        //
        // 32 channels, each = +1
        //
        // Expected = +32
        // ========================================================

        @(negedge clk);

        for (i = 0; i < 32; i = i + 1)
            rf[i] = 16'sd1;

        in_valid = 1;

        $display(
            "INPUT B at %0t : expected = 32",
            $time
        );


        // ========================================================
        // SET C
        //
        // 32 channels, each = -1
        //
        // Expected = -32
        // ========================================================

        @(negedge clk);

        for (i = 0; i < 32; i = i + 1)
            rf[i] = -16'sd1;

        in_valid = 1;

        $display(
            "INPUT C at %0t : expected = -32",
            $time
        );


        // Stop input
        @(negedge clk);

        in_valid = 0;

        for (i = 0; i < 32; i = i + 1)
            rf[i] = 0;


        // Wait for pipeline
        repeat (20) @(posedge clk);


        if (output_count != 3) begin
            $display("");
            $display(
                "ERROR: Expected 3 outputs, received %0d",
                output_count
            );

            error_count = error_count + 1;
        end


        $display("");
        $display("============================================");

        if (error_count == 0)
            $display("FINAL RESULT: PASS");
        else
            $display(
                "FINAL RESULT: FAIL (%0d errors)",
                error_count
            );

        $display("============================================");

        $finish;

    end


    // ============================================================
    // Output checker
    // ============================================================

    always @(posedge clk) begin

        if (das_valid) begin

            output_count = output_count + 1;

            $display("");
            $display(
                "OUTPUT %0d at %0t : DAS SUM = %0d",
                output_count,
                $time,
                $signed(das_sum)
            );


            // ----------------------------------------------------
            // Check output values
            // ----------------------------------------------------

            case (output_count)

                1: begin
                    if ($signed(das_sum) != -340) begin
                        $display("FAIL: expected -340");
                        error_count = error_count + 1;
                    end
                    else
                        $display("PASS: expected -340");
                end


                2: begin
                    if ($signed(das_sum) != 32) begin
                        $display("FAIL: expected 32");
                        error_count = error_count + 1;
                    end
                    else
                        $display("PASS: expected 32");
                end


                3: begin
                    if ($signed(das_sum) != -32) begin
                        $display("FAIL: expected -32");
                        error_count = error_count + 1;
                    end
                    else
                        $display("PASS: expected -32");
                end

            endcase


            // ----------------------------------------------------
            // Check output spacing
            // ----------------------------------------------------

            if (output_count > 1) begin

                if (($time - last_output_time) != 10) begin

                    $display(
                        "FAIL: output spacing = %0t",
                        $time - last_output_time
                    );

                    error_count = error_count + 1;

                end
                else begin

                    $display(
                        "PASS: output spacing = 10 ns"
                    );

                end

            end

            last_output_time = $time;

        end

    end

endmodule