`include "timescale.svh"
module state_timebase #(
    parameter int INC_DEC_INTERVAL = 12000,
    parameter int INC_DEC_MAX      = 167,
    parameter int STATE_COUNT      = 6
)(
    input  logic       clk,           // System clock
    input  logic       rst_n,         // Active-low asynchronous reset
    input  logic [2:0] initial_state, // Starting state (allows custom initial state)

    output logic       ms_tick,       // 1ms tick signal (high for one clock cycle every ms)
    output logic [2:0] current_state  // Current state output
);

    logic [$clog2(INC_DEC_INTERVAL)-1:0] tick_counter; // Counts clock cycles up to INC_DEC_INTERVAL - 1 to generate 1ms tick
    logic [$clog2(INC_DEC_MAX)-1:0]      inc_dec_counter; // Counts number of 1ms intervals elapsed, used to time how long to stay in each state

    assign ms_tick = (tick_counter == INC_DEC_INTERVAL - 1); // ms_tick is asserted when tick_counter reaches its max value every 1 ms

    // Sequential logic block: counting and state transitions
    always_ff @(posedge clk or negedge rst_n) begin
        
        if (!rst_n) begin
            
            tick_counter    <= '0;
            inc_dec_counter <= '0;
            current_state   <= initial_state % STATE_COUNT;
        // ---------- 1ms tick generation ----------
        end else begin
            // wrap back to 0 after INC_DEC_INTERVAL-1.
            tick_counter <= (tick_counter < INC_DEC_INTERVAL - 1)
                            ? tick_counter + 1
                            : '0;
            // ---------- Per-state timing and advance ----------
            if (ms_tick) begin
                // Count the number of ms ticks elapsed in this state.
                inc_dec_counter <= (inc_dec_counter < INC_DEC_MAX - 1)
                                   ? inc_dec_counter + 1
                                   : '0;
                // When the ms counter wraps (just reached its max), advance to the next state; wrap to 0 at STATE_COUNT-1.
                if (inc_dec_counter == INC_DEC_MAX - 1)
                    current_state <= (current_state == STATE_COUNT - 1)
                                     ? 3'd0
                                     : current_state + 1;
            
            end
        
        end

    end
    
endmodule