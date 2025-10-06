`include "timescale.svh"
module pwm_duty_engine #(
    parameter int PWM_INTERVAL = 1200,
    parameter int STEP_VAL     = 1200/167
)(
    input  logic       clk,            // System clock
    input  logic       rst_n,          // Active-low asynchronous reset
    input  logic       ms_tick,        // 1ms tick from timebase
    input  logic [2:0] current_state,  // Current state index to fetch duty info
    output logic       variable_duty_pwm  // PWM output signal with variable duty cycle
);

    localparam int DUTY_W = $clog2(PWM_INTERVAL); // Width of the counters, based on PWM_INTERVAL

    logic [DUTY_W-1:0] pwm_counter; // PWM period counter counts from 0 to PWM_INTERVAL-1
    logic [DUTY_W-1:0] duty_value; // Current duty value within PWM period (0 to PWM_INTERVAL)
    
    // Outputs from the state lookup table
    logic [11:0] base_duty;
    logic        ramp_enable;

    // Instantiate the duty lookup table for the current state
    pwm_state_lookup LUT_I (
        .state(current_state),
        .base_duty(base_duty),
        .ramp_enable(ramp_enable)
    );

    // PWM counter increments each clock cycle and resets after PWM_INTERVAL
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) 
            pwm_counter <= '0;
        else 
            pwm_counter <= (pwm_counter < PWM_INTERVAL - 1) ? pwm_counter + 1 : '0;

    // Duty Value Update (smooth ramp / step transitions)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            duty_value <= 0;
        end else if (ms_tick) begin
            // Only update every 1 ms tick
            if (ramp_enable) begin
                // Smooth RAMP (increase or decrease)
                if (duty_value < base_duty)
                    duty_value <= duty_value + STEP_VAL;   // ramp up
                else if (duty_value > base_duty)
                    duty_value <= duty_value - STEP_VAL;   // ramp down
            end else begin
                // INSTANT STEP (hold or set to base_duty)
                duty_value <= base_duty;
            end
        end
    end
    // PWM output is active high when pwm_counter is less than duty_value
    assign variable_duty_pwm = (pwm_counter < duty_value);

endmodule
