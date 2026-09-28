`timescale 1ns / 1ps

module das_tx_full_integration_tb;

    localparam TOTAL_RF_SAMPLES = 3686400;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    reg clk;
    reg rst_n;

    // ============================================================
    // PIXEL / EVENT
    // ============================================================

    reg        start_valid;
    reg [4:0]  aperture_idx;
    reg [6:0]  event_idx;

    reg [31:0] x_pixel;
    reg [31:0] z_pixel;

    // ============================================================
    // VERIFIED DLG DELAYS
    // ============================================================

    reg [31:0] tx_delay [0:7];

    // ============================================================
    // TX TIME
    // ============================================================

    wire        tx_time_valid;
    wire [31:0] tx_time;

    // ============================================================
    // RX TIMES
    // ============================================================

    wire        rx_time_valid;
    wire [31:0] rx_time [0:31];

    // ============================================================
    // TOF
    // ============================================================

    wire        tof_valid;
    wire [31:0] tof [0:31];

    // ============================================================
    // SAMPLE INDEX
    // ============================================================

    wire        sample_index_valid;
    wire [31:0] sample_index [0:31];

    // ============================================================
    // RF ADDRESS
    // ============================================================

    wire        address_valid;
    wire [21:0] rf_addr [0:31];

    // ============================================================
    // RF MEMORY
    // ============================================================

    reg signed [15:0] rf_mem [0:TOTAL_RF_SAMPLES-1];

    reg signed [15:0] rf_sample [0:31];

    reg adder_in_valid;

    // ============================================================
    // FINAL DAS OUTPUT
    // ============================================================

    wire signed [20:0] das_sum;
    wire               das_valid;

    integer i;


    // ============================================================
    // CLOCK = 100 MHz
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // TX TIME
    // ============================================================

    das_tx_time u_tx_time (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(start_valid),

        .aperture_idx(aperture_idx),

        .x_pixel(x_pixel),
        .z_pixel(z_pixel),

        .tx_delay_0(tx_delay[0]),
        .tx_delay_1(tx_delay[1]),
        .tx_delay_2(tx_delay[2]),
        .tx_delay_3(tx_delay[3]),
        .tx_delay_4(tx_delay[4]),
        .tx_delay_5(tx_delay[5]),
        .tx_delay_6(tx_delay[6]),
        .tx_delay_7(tx_delay[7]),

        .tx_time_valid(tx_time_valid),
        .tx_time(tx_time)
    );


    // ============================================================
    // RX TIME
    // ============================================================

    das_delay u_rx_delay (

        .clk(clk),
        .rst_n(rst_n),

        .pixel_valid(start_valid),

        .x_pixel(x_pixel),
        .z_pixel(z_pixel),

        .rx_time_valid(rx_time_valid),

        .rx_time_0(rx_time[0]),
        .rx_time_1(rx_time[1]),
        .rx_time_2(rx_time[2]),
        .rx_time_3(rx_time[3]),
        .rx_time_4(rx_time[4]),
        .rx_time_5(rx_time[5]),
        .rx_time_6(rx_time[6]),
        .rx_time_7(rx_time[7]),
        .rx_time_8(rx_time[8]),
        .rx_time_9(rx_time[9]),
        .rx_time_10(rx_time[10]),
        .rx_time_11(rx_time[11]),
        .rx_time_12(rx_time[12]),
        .rx_time_13(rx_time[13]),
        .rx_time_14(rx_time[14]),
        .rx_time_15(rx_time[15]),
        .rx_time_16(rx_time[16]),
        .rx_time_17(rx_time[17]),
        .rx_time_18(rx_time[18]),
        .rx_time_19(rx_time[19]),
        .rx_time_20(rx_time[20]),
        .rx_time_21(rx_time[21]),
        .rx_time_22(rx_time[22]),
        .rx_time_23(rx_time[23]),
        .rx_time_24(rx_time[24]),
        .rx_time_25(rx_time[25]),
        .rx_time_26(rx_time[26]),
        .rx_time_27(rx_time[27]),
        .rx_time_28(rx_time[28]),
        .rx_time_29(rx_time[29]),
        .rx_time_30(rx_time[30]),
        .rx_time_31(rx_time[31])
    );


    // ============================================================
    // IMPORTANT:
    //
    // TX_TIME and RX_TIME have DIFFERENT pipeline latencies.
    //
    // Therefore we must not simply connect rx_time_valid to TOF
    // while using tx_time directly unless both results belong to
    // the same pixel and are simultaneously available.
    //
    // For this single-pixel verification, store TX_TIME when ready.
    // Then start TOF when RX_TIME is ready AND TX_TIME has arrived.
    // ============================================================

// ============================================================
// TX/RX ALIGNMENT FOR SINGLE-PIXEL INTEGRATION TEST
//
// TX_TIME and RX_TIME have different pipeline latencies.
// Capture both results first.
//
// IMPORTANT:
// For this verification TB, TOF valid is asserted at a negedge,
// held across the following posedge, and deasserted at the next
// negedge. This matches the already-verified das_tof_tb stimulus.
// ============================================================

reg [31:0] tx_time_hold;
reg [31:0] rx_hold [0:31];

reg tx_captured;
reg rx_captured;

reg tof_start;

integer k;


// ------------------------------------------------------------
// Capture TX_TIME and RX_TIME when each pipeline finishes
// ------------------------------------------------------------
always @(posedge clk) begin

    if (!rst_n) begin

        tx_time_hold <= 32'd0;

        tx_captured <= 1'b0;
        rx_captured <= 1'b0;

        for (k = 0; k < 32; k = k + 1)
            rx_hold[k] <= 32'd0;

    end
    else begin

        if (tx_time_valid) begin
            tx_time_hold <= tx_time;
            tx_captured  <= 1'b1;
        end

        if (rx_time_valid) begin
            for (k = 0; k < 32; k = k + 1)
                rx_hold[k] <= rx_time[k];

            rx_captured <= 1'b1;
        end

    end

end


// ------------------------------------------------------------
// Generate one clean TOF input-valid pulse.
//
// Assert at negedge -> stable before next posedge.
// Deassert at following negedge.
// ------------------------------------------------------------
initial begin

    tof_start = 1'b0;

    wait(rst_n == 1'b1);

    wait((tx_captured == 1'b1) &&
         (rx_captured == 1'b1));

    @(negedge clk);
    tof_start = 1'b1;

    @(negedge clk);
    tof_start = 1'b0;

end


    // ============================================================
    // TOF
    // ============================================================

    das_tof u_tof (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(tof_start),

        .tx_time(tx_time_hold),

        .rx_time_0(rx_hold[0]),
        .rx_time_1(rx_hold[1]),
        .rx_time_2(rx_hold[2]),
        .rx_time_3(rx_hold[3]),
        .rx_time_4(rx_hold[4]),
        .rx_time_5(rx_hold[5]),
        .rx_time_6(rx_hold[6]),
        .rx_time_7(rx_hold[7]),
        .rx_time_8(rx_hold[8]),
        .rx_time_9(rx_hold[9]),
        .rx_time_10(rx_hold[10]),
        .rx_time_11(rx_hold[11]),
        .rx_time_12(rx_hold[12]),
        .rx_time_13(rx_hold[13]),
        .rx_time_14(rx_hold[14]),
        .rx_time_15(rx_hold[15]),
        .rx_time_16(rx_hold[16]),
        .rx_time_17(rx_hold[17]),
        .rx_time_18(rx_hold[18]),
        .rx_time_19(rx_hold[19]),
        .rx_time_20(rx_hold[20]),
        .rx_time_21(rx_hold[21]),
        .rx_time_22(rx_hold[22]),
        .rx_time_23(rx_hold[23]),
        .rx_time_24(rx_hold[24]),
        .rx_time_25(rx_hold[25]),
        .rx_time_26(rx_hold[26]),
        .rx_time_27(rx_hold[27]),
        .rx_time_28(rx_hold[28]),
        .rx_time_29(rx_hold[29]),
        .rx_time_30(rx_hold[30]),
        .rx_time_31(rx_hold[31]),

        .tof_valid(tof_valid),

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
        .tof_31(tof[31])
    );


    // ============================================================
    // SAMPLE INDEX
    // ============================================================

    das_sample_index u_sample_index (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(tof_valid),

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
    // RF ADDRESS GENERATOR
    // ============================================================

    das_rf_read u_rf_read (

        .clk(clk),
        .rst_n(rst_n),

        .in_valid(sample_index_valid),
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
    // SIMULATION RF MEMORY READ
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
    // 32-CHANNEL ADDER
    // ============================================================

    das_adder_tree u_adder (

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
    // TEST
    // ============================================================

    initial begin

        rst_n       = 1'b0;
        start_valid = 1'b0;

        aperture_idx = 5'd0;
        event_idx    = 7'd0;

        // x = 0 mm
        x_pixel = 32'h00000000;

        // z = 30 mm
        z_pixel = 32'h41F00000;


        // ========================================================
        // VERIFIED DLG DELAYS
        // Aperture 0, angle = 40 degrees
        // ========================================================

        tx_delay[0] = 32'h00000000;
        tx_delay[1] = 32'h3D800DA5;
        tx_delay[2] = 32'h3DFF1910;
        tx_delay[3] = 32'h3E3E8F3A;
        tx_delay[4] = 32'h3E7D0C61;
        tx_delay[5] = 32'h3E9D80BA;
        tx_delay[6] = 32'h3EBC35F6;
        tx_delay[7] = 32'h3EDAA4C9;


        // Reset
        repeat (10) @(posedge clk);

        rst_n = 1'b1;

        repeat (5) @(posedge clk);


        // Launch pixel into TX and RX pipelines
        @(negedge clk);

        start_valid = 1'b1;

        $display("============================================================");
        $display("TX_TIME -> RX_TIME -> TOF -> RF -> DAS INTEGRATION");
        $display("============================================================");
        $display("Aperture = 0");
        $display("Angle    = 40 deg");
        $display("Event    = 0");
        $display("Pixel    = x=0 mm, z=30 mm");
        $display("");
        $display("Expected TX_TIME ~= 40A33FBB");
        $display("Expected DAS SUM = -340");
        $display("");


        @(negedge clk);

        start_valid = 1'b0;


        // Allow complete floating-point pipeline to finish
        repeat (1000) @(posedge clk);
        $display("");
        $display("ERROR: Final DAS output never arrived.");
        $finish;

    end


    // ============================================================
    // DEBUG: TX TIME
    // ============================================================

    always @(posedge clk) begin

        if (tx_time_valid) begin

            $display("");
            $display("TX TIME VALID at %0t", $time);
            $display("TX_TIME HEX = %h", tx_time);

            if (tx_time == 32'h40A33FBB)
                $display("TX_TIME CHECK: PASS");
            else begin
                $display("TX_TIME CHECK: DIFFERENT");
                $display("Expected = 40A33FBB");
                $display("Actual   = %h", tx_time);
            end

        end

    end


    // ============================================================
    // DEBUG: RX TIME
    // ============================================================

    always @(posedge clk) begin

        if (rx_time_valid) begin

            $display("");
            $display("RX TIME VALID at %0t", $time);

            $display(
                "RX00=%h RX15=%h RX16=%h RX31=%h",
                rx_time[0],
                rx_time[15],
                rx_time[16],
                rx_time[31]
            );

        end

    end


    // ============================================================
    // DEBUG: TOF START
    // ============================================================

    always @(posedge clk) begin

        if (tof_start) begin

            $display("");
            $display("TOF START at %0t", $time);
            $display("Stored TX_TIME = %h", tx_time_hold);

        end

    end


    // ============================================================
    // DEBUG: TOF
    // ============================================================

    always @(posedge clk) begin

        if (tof_valid) begin

            $display("");
            $display("TOF VALID at %0t", $time);

            $display(
                "TOF00=%h TOF15=%h TOF16=%h TOF31=%h",
                tof[0],
                tof[15],
                tof[16],
                tof[31]
            );

        end

    end


    // ============================================================
    // DEBUG: SAMPLE INDICES
    // ============================================================

    always @(posedge clk) begin

        if (sample_index_valid) begin

            $display("");
            $display("============================================================");
            $display("AUTOMATIC SAMPLE INDICES");
            $display("============================================================");

            for (i = 0; i < 32; i = i + 1)
                $display(
                    "RX%02d : %0d",
                    i,
                    sample_index[i]
                );

        end

    end


    // ============================================================
    // DEBUG: RF SAMPLES
    // ============================================================

    always @(posedge clk) begin

        if (adder_in_valid) begin

            $display("");
            $display("============================================================");
            $display("REAL RF SAMPLES");
            $display("============================================================");

            for (i = 0; i < 32; i = i + 1)
                $display(
                    "RX%02d : RF=%0d",
                    i,
                    $signed(rf_sample[i])
                );

        end

    end


    // ============================================================
    // FINAL CHECK
    // ============================================================

    always @(posedge clk) begin

        if (das_valid) begin

            $display("");
            $display("============================================================");
            $display("FINAL DAS EVENT OUTPUT");
            $display("============================================================");

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

            $display("============================================================");
            $display("");

            $finish;

        end

    end
always @(posedge clk) begin
    if (rst_n) begin

        if (tof_start) begin
            $display("");
            $display("===== TOF INPUT ACCEPT CHECK =====");
            $display("time      = %0t", $time);
            $display("tof_start = %b", tof_start);
            $display("tx_hold   = %h", tx_time_hold);
            $display("rx_hold0  = %h", rx_hold[0]);
            $display("rx_hold15 = %h", rx_hold[15]);
            $display("rx_hold16 = %h", rx_hold[16]);
            $display("rx_hold31 = %h", rx_hold[31]);
        end

        // Directly inspect a few FP-adder valid outputs
        if (u_tof.tof_lane_valid[0] ||
            u_tof.tof_lane_valid[15] ||
            u_tof.tof_lane_valid[16] ||
            u_tof.tof_lane_valid[31]) begin

            $display("");
            $display("===== TOF LANE VALID DEBUG =====");
            $display("time = %0t", $time);
            $display("lane0  valid = %b", u_tof.tof_lane_valid[0]);
            $display("lane15 valid = %b", u_tof.tof_lane_valid[15]);
            $display("lane16 valid = %b", u_tof.tof_lane_valid[16]);
            $display("lane31 valid = %b", u_tof.tof_lane_valid[31]);
        end

        if (tof_valid) begin
            $display("");
            $display("===== TOF VALID =====");
            $display("time  = %0t", $time);
            $display("TOF00 = %h", tof[0]);
            $display("TOF15 = %h", tof[15]);
            $display("TOF16 = %h", tof[16]);
            $display("TOF31 = %h", tof[31]);
        end

    end
end
always @(posedge clk) begin
    if (rst_n) begin

        if (tof_start) begin
            $display("");
            $display("===== DIRECT IP INPUT CHECK =====");
            $display("time = %0t", $time);

            $display(
                "TOF module in_valid = %b",
                u_tof.in_valid
            );

            $display(
                "lane0 A valid = %b",
                u_tof.TOF_ADDERS[0].add_tof.s_axis_a_tvalid
            );

            $display(
                "lane0 B valid = %b",
                u_tof.TOF_ADDERS[0].add_tof.s_axis_b_tvalid
            );

            $display(
                "lane0 A data  = %h",
                u_tof.TOF_ADDERS[0].add_tof.s_axis_a_tdata
            );

            $display(
                "lane0 B data  = %h",
                u_tof.TOF_ADDERS[0].add_tof.s_axis_b_tdata
            );

        end
    end
end
endmodule