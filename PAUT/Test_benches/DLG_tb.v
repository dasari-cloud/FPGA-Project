`timescale 1ns/1ps

//======================================================================
// DLG_tb.v
//
// BACK-TO-BACK PIPELINE TEST
//
// 32 physical elements
// 8 active TX elements
// 25 sliding apertures
// 3 steering angles
//
// Event order:
//
// A0/40
// A0/55
// A0/70
// A1/40
// A1/55
// A1/70
// ...
// A24/40
// A24/55
// A24/70
//
// TOTAL = 75 EVENTS
//
// IMPORTANT:
//
// Unlike the previous functional TB, this TB DOES NOT wait for
// delay_valid before sending the next event.
//
// One new event is applied every clock.
//
// Goal:
//
//   75 consecutive input events
//          |
//          v
//      DLG pipeline
//          |
//          v
//   75 consecutive output events
//
// This proves initiation interval:
//
//             II = 1
//
//======================================================================

module DLG_tb;


//======================================================================
// INPUTS
//======================================================================

reg clk;
reg rst_n;

reg in_valid;

reg [4:0] aperture_idx;

reg [31:0] focus;

reg [31:0] sin_theta;
reg [31:0] cos_theta;


//======================================================================
// OUTPUTS
//======================================================================

//---------------------------------------------------------------------
// Focal point
//---------------------------------------------------------------------

wire focal_valid;

wire [31:0] x_focus;
wire [31:0] z_focus;


//---------------------------------------------------------------------
// Distances
//---------------------------------------------------------------------

wire distances_valid;

wire [31:0] distance_0;
wire [31:0] distance_1;
wire [31:0] distance_2;
wire [31:0] distance_3;
wire [31:0] distance_4;
wire [31:0] distance_5;
wire [31:0] distance_6;
wire [31:0] distance_7;


//---------------------------------------------------------------------
// Maximum distance
//---------------------------------------------------------------------

wire dmax_valid;

wire [31:0] d_max;


//---------------------------------------------------------------------
// Delta distance
//---------------------------------------------------------------------

wire delta_valid;

wire [31:0] delta_d0;
wire [31:0] delta_d1;
wire [31:0] delta_d2;
wire [31:0] delta_d3;
wire [31:0] delta_d4;
wire [31:0] delta_d5;
wire [31:0] delta_d6;
wire [31:0] delta_d7;


//---------------------------------------------------------------------
// Final delays
//---------------------------------------------------------------------

wire delay_valid;

wire [31:0] delay_0;
wire [31:0] delay_1;
wire [31:0] delay_2;
wire [31:0] delay_3;
wire [31:0] delay_4;
wire [31:0] delay_5;
wire [31:0] delay_6;
wire [31:0] delay_7;


//======================================================================
// CONSTANTS
//======================================================================

// Focus = 65.0 mm

localparam [31:0] FOCUS_65 =
    32'h42820000;


//---------------------------------------------------------------------
// 40 degrees
//---------------------------------------------------------------------

localparam [31:0] SIN_40 =
    32'h3F248DBB;

localparam [31:0] COS_40 =
    32'h3F441B7D;


//---------------------------------------------------------------------
// 55 degrees
//---------------------------------------------------------------------

localparam [31:0] SIN_55 =
    32'h3F51B3F3;

localparam [31:0] COS_55 =
    32'h3F12D0E5;


//---------------------------------------------------------------------
// 70 degrees
//---------------------------------------------------------------------

localparam [31:0] SIN_70 =
    32'h3F708FB2;

localparam [31:0] COS_70 =
    32'h3EAF1D44;


//======================================================================
// DUT
//======================================================================

DLG dut (

    .clk             (clk),
    .rst_n           (rst_n),

    .in_valid        (in_valid),

    .aperture_idx    (aperture_idx),

    .focus           (focus),

    .sin_theta       (sin_theta),
    .cos_theta       (cos_theta),


    //--------------------------------------------------------------
    // Focal point
    //--------------------------------------------------------------

    .focal_valid     (focal_valid),

    .x_focus         (x_focus),
    .z_focus         (z_focus),


    //--------------------------------------------------------------
    // Distances
    //--------------------------------------------------------------

    .distances_valid (distances_valid),

    .distance_0      (distance_0),
    .distance_1      (distance_1),
    .distance_2      (distance_2),
    .distance_3      (distance_3),

    .distance_4      (distance_4),
    .distance_5      (distance_5),
    .distance_6      (distance_6),
    .distance_7      (distance_7),


    //--------------------------------------------------------------
    // d_max
    //--------------------------------------------------------------

    .dmax_valid      (dmax_valid),
    .d_max           (d_max),


    //--------------------------------------------------------------
    // Delta distance
    //--------------------------------------------------------------

    .delta_valid     (delta_valid),

    .delta_d0        (delta_d0),
    .delta_d1        (delta_d1),
    .delta_d2        (delta_d2),
    .delta_d3        (delta_d3),

    .delta_d4        (delta_d4),
    .delta_d5        (delta_d5),
    .delta_d6        (delta_d6),
    .delta_d7        (delta_d7),


    //--------------------------------------------------------------
    // Final delays
    //--------------------------------------------------------------

    .delay_valid     (delay_valid),

    .delay_0         (delay_0),
    .delay_1         (delay_1),
    .delay_2         (delay_2),
    .delay_3         (delay_3),

    .delay_4         (delay_4),
    .delay_5         (delay_5),
    .delay_6         (delay_6),
    .delay_7         (delay_7)

);


//======================================================================
// CLOCK
//
// 100 MHz
//
// Period = 10 ns
//======================================================================

initial begin

    clk = 1'b0;

end


always #5 clk = ~clk;


//======================================================================
// SCOREBOARD
//
// Store the event information in the exact order in which events
// enter the DLG.
//
// When delay_valid arrives, read the corresponding entry.
//======================================================================

reg [4:0] expected_aperture [0:74];

integer expected_angle [0:74];

integer write_ptr;
integer read_ptr;


//======================================================================
// COUNTERS
//======================================================================

integer input_count;
integer output_count;

integer error_count;

integer consecutive_output_count;

integer previous_output_time;

integer current_output_time;


//======================================================================
// LOOP VARIABLES
//======================================================================

integer ap;


//======================================================================
// TASK: DRIVE ONE EVENT
//
// IMPORTANT:
//
// This task does NOT wait for the result.
//
// Each call consumes exactly one input clock.
//======================================================================

task drive_event;

    input [4:0] ap_index;

    input integer angle_deg;

    input [31:0] sin_value;
    input [31:0] cos_value;

    begin

        //--------------------------------------------------------------
        // Drive data at falling edge.
        //
        // Therefore signals are stable before next rising edge.
        //--------------------------------------------------------------

        @(negedge clk);


        aperture_idx =
            ap_index;

        sin_theta =
            sin_value;

        cos_theta =
            cos_value;

        in_valid =
            1'b1;


        //--------------------------------------------------------------
        // Store expected event
        //--------------------------------------------------------------

        expected_aperture[write_ptr] =
            ap_index;

        expected_angle[write_ptr] =
            angle_deg;


        //--------------------------------------------------------------
        // Input accounting
        //--------------------------------------------------------------

        write_ptr =
            write_ptr + 1;

        input_count =
            input_count + 1;


        //--------------------------------------------------------------
        // Print compact input information
        //--------------------------------------------------------------

        $display(
            "INPUT  %0d : time=%0t : A%0d / %0d deg : E%0d-E%0d",
            input_count,
            $time,
            ap_index,
            angle_deg,
            ap_index,
            ap_index + 7
        );

    end

endtask


//======================================================================
//
// OUTPUT SCOREBOARD
//
// Sample output on clock edge where delay_valid is asserted.
//
//======================================================================

always @(posedge clk) begin

    if (rst_n && delay_valid) begin


        //--------------------------------------------------------------
        // Count output
        //--------------------------------------------------------------

        output_count =
            output_count + 1;


        //--------------------------------------------------------------
        // Safety: should never receive more than 75 outputs
        //--------------------------------------------------------------

        if (read_ptr >= 75) begin

            $display("");
            $display(
                "ERROR : EXTRA OUTPUT RECEIVED AT TIME %0t",
                $time
            );

            error_count =
                error_count + 1;

        end

        else begin


            //----------------------------------------------------------
            // Display event mapping
            //----------------------------------------------------------

            $display("");

            $display(
                "OUTPUT %0d : time=%0t : expected A%0d / %0d deg",
                output_count,
                $time,
                expected_aperture[read_ptr],
                expected_angle[read_ptr]
            );


            $display(
                "DELAYS : %08h %08h %08h %08h %08h %08h %08h %08h",
                delay_0,
                delay_1,
                delay_2,
                delay_3,
                delay_4,
                delay_5,
                delay_6,
                delay_7
            );


            //----------------------------------------------------------
            // Check X/Z
            //----------------------------------------------------------

            if (
                   (^delay_0 === 1'bx)
                || (^delay_1 === 1'bx)
                || (^delay_2 === 1'bx)
                || (^delay_3 === 1'bx)
                || (^delay_4 === 1'bx)
                || (^delay_5 === 1'bx)
                || (^delay_6 === 1'bx)
                || (^delay_7 === 1'bx)
            ) begin

                $display(
                    "ERROR : X/Z VALUE DETECTED"
                );

                error_count =
                    error_count + 1;

            end


            //----------------------------------------------------------
            // For our positive steering angles:
            //
            // lane 0 has maximum propagation distance.
            //
            // Therefore its TX delay must be zero.
            //----------------------------------------------------------

            if (delay_0 !== 32'h00000000) begin

                $display(
                    "ERROR : delay_0 IS NOT ZERO"
                );

                error_count =
                    error_count + 1;

            end


            //----------------------------------------------------------
            // Delay should increase from lane 0 -> lane 7.
            //
            // All delays are positive finite FLOAT32 values.
            //----------------------------------------------------------

            if (
                   !(delay_0 <= delay_1)
                || !(delay_1 <= delay_2)
                || !(delay_2 <= delay_3)
                || !(delay_3 <= delay_4)
                || !(delay_4 <= delay_5)
                || !(delay_5 <= delay_6)
                || !(delay_6 <= delay_7)
            ) begin

                $display(
                    "ERROR : DELAY VECTOR IS NOT MONOTONIC"
                );

                error_count =
                    error_count + 1;

            end


            //----------------------------------------------------------
            // Throughput check
            //
            // Once outputs start, next output should arrive exactly
            // 10 ns later because input events were consecutive.
            //----------------------------------------------------------

            current_output_time =
                $time;


            if (output_count > 1) begin

                if (
                    (current_output_time -
                     previous_output_time) != 10
                ) begin

                    $display(
                        "ERROR : OUTPUT GAP = %0d ns, EXPECTED 10 ns",
                        current_output_time -
                        previous_output_time
                    );

                    error_count =
                        error_count + 1;

                end

                else begin

                    consecutive_output_count =
                        consecutive_output_count + 1;

                end

            end


            previous_output_time =
                current_output_time;


            //----------------------------------------------------------
            // Move scoreboard pointer
            //----------------------------------------------------------

            read_ptr =
                read_ptr + 1;

        end

    end

end


//======================================================================
// OPTIONAL PIPELINE COUNTERS
//======================================================================

integer focal_count;
integer distance_count;
integer dmax_count;
integer delta_count;


always @(posedge clk) begin

    if (rst_n && focal_valid)
        focal_count = focal_count + 1;

end


always @(posedge clk) begin

    if (rst_n && distances_valid)
        distance_count = distance_count + 1;

end


always @(posedge clk) begin

    if (rst_n && dmax_valid)
        dmax_count = dmax_count + 1;

end


always @(posedge clk) begin

    if (rst_n && delta_valid)
        delta_count = delta_count + 1;

end


//======================================================================
//
// MAIN TEST
//
//======================================================================

initial begin


    //==================================================================
    // INITIAL VALUES
    //==================================================================

    rst_n =
        1'b0;

    in_valid =
        1'b0;

    aperture_idx =
        5'd0;

    focus =
        FOCUS_65;

    sin_theta =
        32'h00000000;

    cos_theta =
        32'h00000000;


    //--------------------------------------------------------------
    // Scoreboard
    //--------------------------------------------------------------

    write_ptr =
        0;

    read_ptr =
        0;


    //--------------------------------------------------------------
    // Counters
    //--------------------------------------------------------------

    input_count =
        0;

    output_count =
        0;

    error_count =
        0;

    consecutive_output_count =
        0;


    previous_output_time =
        0;

    current_output_time =
        0;


    focal_count =
        0;

    distance_count =
        0;

    dmax_count =
        0;

    delta_count =
        0;


    //==================================================================
    // RESET
    //==================================================================

    repeat (10)
        @(posedge clk);


    rst_n =
        1'b1;


    repeat (5)
        @(posedge clk);


    //==================================================================
    // TEST START
    //==================================================================

    $display("");
    $display("");
    $display("############################################################");
    $display("BACK-TO-BACK 75-EVENT DLG TEST");
    $display("############################################################");

    $display(
        "Clock period        = 10 ns"
    );

    $display(
        "Input throughput    = 1 event / clock"
    );

    $display(
        "Expected events     = 75"
    );

    $display("");


    //==================================================================
    //
    // SEND ALL 75 EVENTS
    //
    // NO WAIT FOR OUTPUTS
    //
    //==================================================================

    for (ap = 0; ap < 25; ap = ap + 1) begin


        //--------------------------------------------------------------
        // 40 degrees
        //--------------------------------------------------------------

        drive_event(
            ap,
            40,
            SIN_40,
            COS_40
        );


        //--------------------------------------------------------------
        // 55 degrees
        //--------------------------------------------------------------

        drive_event(
            ap,
            55,
            SIN_55,
            COS_55
        );


        //--------------------------------------------------------------
        // 70 degrees
        //--------------------------------------------------------------

        drive_event(
            ap,
            70,
            SIN_70,
            COS_70
        );

    end


    //==================================================================
    // STOP INPUT STREAM
    //==================================================================

    @(negedge clk);

    in_valid =
        1'b0;


    sin_theta =
        32'h00000000;

    cos_theta =
        32'h00000000;


    $display("");
    $display("------------------------------------------------------------");

    $display(
        "ALL INPUT EVENTS SENT AT TIME %0t",
        $time
    );

    $display(
        "INPUT COUNT = %0d",
        input_count
    );

    $display("------------------------------------------------------------");


    //==================================================================
    // WAIT FOR ALL OUTPUTS
    //==================================================================

    wait(output_count == 75);


    //--------------------------------------------------------------
    // Allow pipeline to become idle
    //--------------------------------------------------------------

    repeat (10)
        @(posedge clk);


    //==================================================================
    //
    // FINAL REPORT
    //
    //==================================================================

    $display("");
    $display("");
    $display("############################################################");
    $display("BACK-TO-BACK TEST REPORT");
    $display("############################################################");


    $display(
        "INPUT EVENTS       = %0d",
        input_count
    );

    $display(
        "FOCAL OUTPUTS      = %0d",
        focal_count
    );

    $display(
        "DISTANCE OUTPUTS   = %0d",
        distance_count
    );

    $display(
        "DMAX OUTPUTS       = %0d",
        dmax_count
    );

    $display(
        "DELTA OUTPUTS      = %0d",
        delta_count
    );

    $display(
        "FINAL OUTPUTS      = %0d",
        output_count
    );

    $display(
        "SCOREBOARD READS   = %0d",
        read_ptr
    );

    $display(
        "10 ns OUTPUT GAPS  = %0d / 74",
        consecutive_output_count
    );

    $display(
        "ERROR COUNT        = %0d",
        error_count
    );


    //==================================================================
    // FINAL PASS / FAIL
    //==================================================================

    if (
           (input_count == 75)
        && (focal_count == 75)
        && (distance_count == 75)
        && (dmax_count == 75)
        && (delta_count == 75)
        && (output_count == 75)
        && (read_ptr == 75)
        && (consecutive_output_count == 74)
        && (error_count == 0)
    ) begin

        $display("");
        $display("============================================================");
        $display("RESULT : PASS");
        $display("");
        $display("ALL 75 EVENTS PASSED THROUGH THE PIPELINE");
        $display("ONE EVENT WAS ACCEPTED EVERY CLOCK");
        $display("ONE RESULT WAS PRODUCED EVERY CLOCK");
        $display("");
        $display("CONFIRMED DLG INITIATION INTERVAL: II = 1");
        $display("============================================================");

    end

    else begin

        $display("");
        $display("============================================================");
        $display("RESULT : FAIL");
        $display("CHECK COUNTS / OUTPUT GAPS / DELAY ERRORS ABOVE");
        $display("============================================================");

    end


    $display("############################################################");
    $display("");


    $finish;

end


//======================================================================
//
// TIMEOUT
//
// Back-to-back input itself requires only:
//
// 75 x 10 ns = 750 ns.
//
// Pipeline then needs time to flush.
//
// 20 us is far more than required.
//
//======================================================================

initial begin

    #20000;


    $display("");
    $display("");
    $display("############################################################");
    $display("ERROR : BACK-TO-BACK TEST TIMEOUT");

    $display(
        "INPUT COUNT  = %0d",
        input_count
    );

    $display(
        "OUTPUT COUNT = %0d",
        output_count
    );

    $display(
        "READ POINTER = %0d",
        read_ptr
    );

    $display(
        "ERROR COUNT  = %0d",
        error_count
    );

    $display("############################################################");


    $finish;

end


endmodule