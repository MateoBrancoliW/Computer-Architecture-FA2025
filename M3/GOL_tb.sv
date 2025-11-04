`timescale 1ns/1ps
`default_nettype none

// Run: iverilog -g2012 -o GOL_tb.vvp GOL_tb.sv top.sv game_of_life.sv memory.sv ws2812b.sv && vvp GOL_tb.vvp && gtkwave gol.vcd

module GOL_tb;

  // Clock Generation (12 MHz → period ≈ 83.333 ns)
  logic clk = 0;
  always #41.666 clk = ~clk;

  // Inputs / Controls
  logic SW   = 1'b1;
  logic BOOT = 1'b1;

  // Output
  logic _45a;

  // Device Under Test (DUT)
  top u0 (
    .clk (clk),
    .SW  (SW),
    .BOOT(BOOT),
    ._45a(_45a)
  );

  // Reset Pulse Sequence (simulate power-on reset)
  initial begin
    BOOT = 1'b0;
    #5000;      // hold reset low for 5 µs
    BOOT = 1'b1;
  end

  // Simulation Duration Control
  localparam SIM_TIME_NS = 200_000_000; // 200 ms @ 12 MHz ≈ ~2.4M cycles

  initial begin
    $dumpfile("gol.vcd");
    $dumpvars(0, GOL_tb);
    // Internal signal dumps for LED analysis
    $dumpvars(0, u0.cur_r, u0.cur_g, u0.cur_b);
    $dumpvars(0, u0.nxt_r, u0.nxt_g, u0.nxt_b);
    $dumpvars(0, u0.shift_reg);
    $dumpvars(0, u0.pixel);
    $dumpvars(0, u0.frame);

    #SIM_TIME_NS;
    $display("\n--- Simulation Finished after %0t ns ---", $time);
    $finish;
  end

  // LED Matrix ASCII Display
  task automatic print_matrix(input string label, input logic [63:0] mat);
    $display("\n=== %s ===", label);
    for (int r = 7; r >= 0; r--) begin
      for (int c = 7; c >= 0; c--)
        $write("%s", mat[r*8 + c] ? "█" : "·");
      $write("\n");
    end
  endtask

  // Frame Display on State Update
  int frame_count = 0;
  always @(posedge u0.apply_r or posedge u0.apply_g or posedge u0.apply_b) begin
    frame_count++;
    $display("\nTIME=%0t ns | FRAME #%0d", $time, frame_count);
    print_matrix("RED",   u0.cur_r);
    print_matrix("GREEN", u0.cur_g);
    print_matrix("BLUE",  u0.cur_b);
  end

endmodule

`default_nettype wire
