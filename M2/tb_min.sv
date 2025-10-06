`include "timescale.svh"
module tb_min;

  // DUT I/O
  logic clk = 0;
  logic SW  = 0;                  // active-low reset input on board
  logic RGB_R, RGB_G, RGB_B;      // active-low LED pins from DUT
  logic LED;                      // active-low mono LED

  // 12 MHz clock → 83.333 ns period
  always #41.666 clk = ~clk;

  // Instantiate board-facing top (ports must match top.sv)
  top #(
    .INC_DEC_INTERVAL(10000),   // 1 ms tick @ 12 MHz
    .INC_DEC_MAX     (200),     // 200 ms per state → 6 states/sec
    .STATE_COUNT     (6),
    .PWM_INTERVAL    (1200)
  ) dut (
    .clk  (clk),
    .SW   (SW),         // active-low reset
    .RGB_R(RGB_R),
    .RGB_G(RGB_G),
    .RGB_B(RGB_B),
    .LED  (LED)
  );

  // Convenience: active-high mirrors to visualize PWM easily
  wire pwm_red   = ~RGB_R;
  wire pwm_green = ~RGB_G;
  wire pwm_blue  = ~RGB_B;

  // VCD dump
  initial begin
    $dumpfile("wave.vcd");

    // Dump whole DUT once (ensures any nets you forgot still get captured)
    $dumpvars(0, tb_min.dut);

    // …and explicitly (redundantly) dump the critical PWM internals per channel
    $dumpvars(0,
      tb_min.dut.red_engine.duty_value,
      tb_min.dut.red_engine.base_duty,
      tb_min.dut.red_engine.ramp_enable,
      tb_min.dut.red_engine.pwm_counter,

      tb_min.dut.green_engine.duty_value,
      tb_min.dut.green_engine.base_duty,
      tb_min.dut.green_engine.ramp_enable,
      tb_min.dut.green_engine.pwm_counter,

      tb_min.dut.blue_engine.duty_value,
      tb_min.dut.blue_engine.base_duty,
      tb_min.dut.blue_engine.ramp_enable,
      tb_min.dut.blue_engine.pwm_counter
    );

    // Board pins + active-high mirrors
    $dumpvars(0, tb_min.RGB_R, tb_min.RGB_G, tb_min.RGB_B, tb_min.LED);
    $dumpvars(0, tb_min.pwm_red, tb_min.pwm_green, tb_min.pwm_blue);
  end

  // Reset sequence and run time
  initial begin
    // Assert reset (SW low) for 2 ms, then release (SW high)
    SW = 1'b0;         // hold in reset (active-low)
    #2_000_000;
    SW = 1'b1;         // release reset

    // Run for 1 second to see 6 states
    #1_000_000_000;
    $display("[%0t] Done 1 second", $time);
    $finish;
  end

endmodule