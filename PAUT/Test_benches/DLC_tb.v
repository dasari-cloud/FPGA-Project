`timescale 1ns/1ps

module DLC_tb;

    reg clk;
    reg rst_n;

    reg        elem_valid;
    reg [31:0] elem_x;

    reg        sin_valid;
    reg [31:0] sin_theta;

    wire        delay_valid;
    wire [31:0] delay_us;


    // ============================================================
    // DUT
    // ============================================================
    DLC #(
        .C_MM_US(5.9)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),

        .elem_valid  (elem_valid),
        .elem_x      (elem_x),

        .sin_valid   (sin_valid),
        .sin_theta   (sin_theta),

        .delay_valid (delay_valid),
        .delay_us    (delay_us)
    );


    // ============================================================
    // Clock
    // 100 MHz
    // ============================================================
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // Test
    // ============================================================
    initial begin

        rst_n      = 1'b0;

        elem_valid = 1'b0;
        elem_x     = 32'hC0F80000;

        sin_valid  = 1'b0;
        sin_theta  = 32'h3F5DB3D7;

        #20;

        rst_n = 1'b1;

        // --------------------------------------------------------
        // E16
        //
        // x = -7.75 mm
        //
        // IEEE-754:
        // -7.75 = 0xC0F80000
        // --------------------------------------------------------
/*        elem_x = 32'hC0F80000;

        // --------------------------------------------------------
        // sin(30 deg) = 0.5
        //
        // IEEE-754:
        // 0.5 = 0x3F000000
        // --------------------------------------------------------
        sin_theta = 32'h3F000000;*/
        elem_x    = 32'hC0F80000;   // -7.75 mm
        sin_theta = 32'h3F5DB3D7;   // sin(60°)
        
        elem_valid = 1'b1;
        sin_valid  = 1'b1;

        #10;

        elem_valid = 1'b0;
        sin_valid  = 1'b0;

        #20;

        $finish;

    end


    // ============================================================
    // Monitor
    // ============================================================
    always @(posedge clk) begin

        if (delay_valid) begin

            $display(
                "TIME=%0t ns | X=%h | SIN=%h | DELAY=%h",
                $time,
                elem_x,
                sin_theta,
                delay_us
            );
            $display(
    "Delay = %f us",
    dut.f32_to_real(delay_us)
);
$display("X decimal   = %f", dut.f32_to_real(elem_x));
$display("SIN decimal = %f", dut.f32_to_real(sin_theta));
$display("Delay       = %f us", dut.f32_to_real(delay_us));

        end

    end

endmodule