`include "timescale.svh"
//=====================================================
// File: top.sv
// Description: IceBlinkPico top-level RGB PWM controller
// - 6 states per second @ 12 MHz  (each state = 1/6 s = 2,000,000 cycles)
// - Shared master timebase with color phase offsets
// - Board LEDs are active-low (outputs inverted)
// - SW is tactile switch (active-low reset)
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
    // Timebase parameters
    parameter int INC_DEC_INTERVAL = 10_000,    // cycles per tick (~0.8333 ms)
    parameter int INC_DEC_MAX      = 200,       // ticks per state (~166.7 ms)
    parameter int STATE_COUNT      = 6,         // 0..5 states (6 total)

    // PWM parameters
    parameter int PWM_INTERVAL     = 1200,      // 10 kHz at 12 MHz
    parameter int STEP_VAL         = (PWM_INTERVAL / INC_DEC_MAX) > 0
                                   ? (PWM_INTERVAL / INC_DEC_MAX) : 1
) (
    // Board I/O (match PCF)
    input  logic clk,    // 12 MHz oscillator (set_io clk 20)
    input  logic SW,     // tactile switch, active-low reset (set_io SW 38)

    output logic RGB_R,  // active-low red LED  (set_io RGB_R 41)
    output logic RGB_G,  // active-low green LED(set_io RGB_G 40)
    output logic RGB_B,  // active-low blue LED (set_io RGB_B 39)
    output logic LED     // mono LED, active-low(set_io LED 42)
);

    // Reset: SW is active-low, so connect directly
    wire rst_n = SW;

    // Shared master timebase (1 tick + state counter) ** realized that without this all states reset to 0 after rst toggles off
    logic ms_tick;
    logic [2:0] master_state;

    state_timebase #(
        .INC_DEC_INTERVAL(INC_DEC_INTERVAL),
        .INC_DEC_MAX     (INC_DEC_MAX),
        .STATE_COUNT     (STATE_COUNT)
    ) master_timebase (
        .clk          (clk),
        .rst_n        (rst_n),
        .initial_state(3'd0),
        .ms_tick      (ms_tick),
        .current_state(master_state)
    );

    // Phase-shifted states for color sequencing
    logic [2:0] state_r, state_g, state_b;

    assign state_r = (master_state + 3'd4) % STATE_COUNT; // Red  phase +4
    assign state_g = (master_state + 3'd2) % STATE_COUNT; // Green phase +2
    assign state_b = (master_state + 3'd0);               // Blue  base phase

    // PWM engines for each color channel
    logic pwm_red, pwm_green, pwm_blue;

    // Red
    pwm_duty_engine #(
        .PWM_INTERVAL (PWM_INTERVAL),
        .STEP_VAL     (STEP_VAL)
    ) red_engine (
        .clk               (clk),
        .rst_n             (rst_n),
        .ms_tick           (ms_tick),
        .current_state     (state_r),
        .variable_duty_pwm (pwm_red)
    );

    // Green
    pwm_duty_engine #(
        .PWM_INTERVAL (PWM_INTERVAL),
        .STEP_VAL     (STEP_VAL)
    ) green_engine (
        .clk               (clk),
        .rst_n             (rst_n),
        .ms_tick           (ms_tick),
        .current_state     (state_g),
        .variable_duty_pwm (pwm_green)
    );

    // Blue
    pwm_duty_engine #(
        .PWM_INTERVAL (PWM_INTERVAL),
        .STEP_VAL     (STEP_VAL)
    ) blue_engine (
        .clk               (clk),
        .rst_n             (rst_n),
        .ms_tick           (ms_tick),
        .current_state     (state_b),
        .variable_duty_pwm (pwm_blue)
    );

    // Board outputs (active-low LEDs)
    assign RGB_R = ~pwm_red;
    assign RGB_G = ~pwm_green;
    assign RGB_B = ~pwm_blue;

endmodule