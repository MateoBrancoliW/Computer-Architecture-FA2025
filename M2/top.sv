`include "timescale.svh"
//=====================================================
// File: top.sv
// Board-facing top (IceBlinkPico pin names) + core PWM logic
// - 6 states per second @ 12 MHz  (each state = 1/6 s = 2,000,000 cycles)
// - Board LEDs are active-low, so outputs are inverted at the pins
// - SW is a tactile switch (active-low) used as reset_n
//=====================================================

    //--------------------------------------------------
    //  state_timebase:
    //    - Generates periodic tick (every INC_DEC_INTERVAL cycles)
    //    - Counts INC_DEC_MAX ticks per state -> 1/6 s per state with params above
    //    - Outputs current_state (0..5) and ms_tick_x (generic "tick")
    //
    //  pwm_duty_engine:
    //    - On each tick, moves duty_value toward base_duty by STEP_VAL if ramp_enable=1
    //    - Generates 10 kHz PWM (PWM_INTERVAL=1200) on variable_duty_pwm
    //    - Looks up base_duty, ramp_enable via pwm_state_lookup
    //--------------------------------------------------

module top #(
    // Timebase parameters (12 MHz clk)
    // Choose INC_DEC_INTERVAL * INC_DEC_MAX = 2_000_000 cycles per state
    parameter int INC_DEC_INTERVAL = 10_000,     // cycles per tick  (~0.8333 ms)
    parameter int INC_DEC_MAX      = 200,        // ticks per state  (~166.667 ms)
    parameter int STATE_COUNT      = 6,          // states 0..5

    // PWM parameters
    parameter int PWM_INTERVAL     = 1200,       // 10 kHz at 12 MHz
    parameter int STEP_VAL         = (PWM_INTERVAL / INC_DEC_MAX) > 0
                                     ? (PWM_INTERVAL / INC_DEC_MAX) : 1
    // STEP_VAL = duty step per tick when ramping (1200/200 = 6)
) (
    // ---- Board I/O (names match PCF) ----
    input  logic clk,     // 12 MHz oscillator  (PCF: set_io clk   20)
    input  logic SW,      // tactile switch, active-low reset (PCF: set_io SW 38)

    output logic RGB_R,   // on-board RGB (active-low) (PCF: set_io RGB_R 41)
    output logic RGB_G,   // (PCF: set_io RGB_G 40)
    output logic RGB_B,   // (PCF: set_io RGB_B 39)
    output logic LED      // mono LED (active-low)      (PCF: set_io LED   42)
);

    // ---------------- Sanity (sim only) ----------------
    localparam int CYCLES_PER_STATE = INC_DEC_INTERVAL * INC_DEC_MAX;
    // synthesis translate_off
    initial begin
        if (CYCLES_PER_STATE != 2_000_000) begin
            $display("WARNING(top): CYCLES_PER_STATE=%0d (expected 2_000_000 for 6 states/sec @ 12 MHz)",
                     CYCLES_PER_STATE);
        end
    end
    // synthesis translate_on

    // ---------------- Reset (SW active-low) ----------------
    // Your core expects rst_n (active-low). SW is active-low already.
    wire rst_n = SW;

    // ---------------- RED channel ----------------
    logic pwm_red;                 // active-high internal PWM
    logic ms_tick_r;
    logic [2:0] state_r;

    state_timebase #(
        .INC_DEC_INTERVAL(INC_DEC_INTERVAL),
        .INC_DEC_MAX     (INC_DEC_MAX),
        .STATE_COUNT     (STATE_COUNT)
    ) red_timebase (
        .clk          (clk),
        .rst_n        (rst_n),
        .initial_state(3'd4), //state 4
        .ms_tick      (ms_tick_r),
        .current_state(state_r)
    );

    pwm_duty_engine #(
        .PWM_INTERVAL (PWM_INTERVAL),
        .STEP_VAL     (STEP_VAL)
    ) red_engine (
        .clk               (clk),
        .rst_n             (rst_n),
        .ms_tick           (ms_tick_r),
        .current_state     (state_r),
        .variable_duty_pwm (pwm_red)
    );

    // ---------------- GREEN channel ----------------
    logic pwm_green;
    logic ms_tick_g;
    logic [2:0] state_g;

    state_timebase #(
        .INC_DEC_INTERVAL(INC_DEC_INTERVAL),
        .INC_DEC_MAX     (INC_DEC_MAX),
        .STATE_COUNT     (STATE_COUNT)
    ) green_timebase (
        .clk          (clk),
        .rst_n        (rst_n),
        .initial_state(3'd2),   // state 2
        .ms_tick      (ms_tick_g),
        .current_state(state_g)
    );

    pwm_duty_engine #(
        .PWM_INTERVAL (PWM_INTERVAL),
        .STEP_VAL     (STEP_VAL)
    ) green_engine (
        .clk               (clk),
        .rst_n             (rst_n),
        .ms_tick           (ms_tick_g),
        .current_state     (state_g),
        .variable_duty_pwm (pwm_green)
    );

    // ---------------- BLUE channel ----------------
    logic pwm_blue;
    logic ms_tick_b;
    logic [2:0] state_b;

    state_timebase #(
        .INC_DEC_INTERVAL(INC_DEC_INTERVAL),
        .INC_DEC_MAX     (INC_DEC_MAX),
        .STATE_COUNT     (STATE_COUNT)
    ) blue_timebase (
        .clk          (clk),
        .rst_n        (rst_n),
        .initial_state(3'd0),   // state 0
        .ms_tick      (ms_tick_b),
        .current_state(state_b)
    );

    pwm_duty_engine #(
        .PWM_INTERVAL (PWM_INTERVAL),
        .STEP_VAL     (STEP_VAL)
    ) blue_engine (
        .clk               (clk),
        .rst_n             (rst_n),
        .ms_tick           (ms_tick_b),
        .current_state     (state_b),
        .variable_duty_pwm (pwm_blue)
    );

    // ---------------- Board outputs (active-low LEDs) ----------------
    // Internal PWM is active-high. Board LEDs are active-low.
    assign RGB_R = ~pwm_red;
    assign RGB_G = ~pwm_green;
    assign RGB_B = ~pwm_blue;

endmodule