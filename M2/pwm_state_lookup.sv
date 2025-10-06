`include "timescale.svh"
module pwm_state_lookup #(
    parameter STATE_COUNT = 6
)(
    input  logic [2:0]  state,
    output logic [11:0] base_duty,
    output logic        ramp_enable
);

    always_comb begin
        case (state)
            // States 0 and 1: completely OFF
            3'd0: begin base_duty = 0;     ramp_enable = 0; end
            3'd1: begin base_duty = 0;     ramp_enable = 0; end

            // State 2: ramp UP to full
            3'd2: begin base_duty = 12'd1200;  ramp_enable = 1; end

            // States 3 and 4: stay at full (step)
            3'd3: begin base_duty = 12'd1200;  ramp_enable = 0; end
            3'd4: begin base_duty = 12'd1200;  ramp_enable = 0; end

            // State 5: ramp DOWN to 0
            3'd5: begin base_duty = 0;     ramp_enable = 1; end

            // Default safety
            default: begin base_duty = 0;  ramp_enable = 0; end
        endcase
    end

endmodule
