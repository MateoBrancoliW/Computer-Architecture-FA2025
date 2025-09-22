module RYBCGM #(
    parameter CLK_CYCLE = 12000000     // CLK freq is 12MHz, so 6,000,000 cycles is 1s
)(
    input logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B, 
    output logic LED
);

    // Define state variable values
    localparam RED = 3'b000;
    localparam YELLOW = 3'b001;
    localparam GREEN = 3'b010;
    localparam CYAN = 3'b011;
    localparam BLUE = 3'b100;
    localparam MAGENTA = 3'b101;

    // Declare state variables
    logic [2:0] current_state = RED;
    logic [2:0] next_state;

    // Declare next output variables for each color
    logic next_red, next_green, next_blue;

    // Prevent overflow in counter
    logic [$clog2(CLK_CYCLE) - 1:0] count = 0;

    // Combinational block for state transitions and output color logic
    always_comb begin
        // Default values for next outputs (i.e., turn off all colors initially)
        next_red = 1'b0;
        next_green = 1'b0;
        next_blue = 1'b0;

        // State machine logic for color outputs
        case (current_state)
            RED: begin
                next_red = 1'b1;  // Red is ON, others OFF
            end
            YELLOW: begin
                next_red = 1'b1;  // Red is ON
                next_green = 1'b1;  // Green is ON (Yellow is a mix of red and green)
            end
            GREEN: begin
                next_green = 1'b1;  // Green is ON
            end
            CYAN: begin
                next_green = 1'b1;  // Green is ON
                next_blue = 1'b1;  // Blue is ON (Cyan is a mix of green and blue)
            end
            BLUE: begin
                next_blue = 1'b1;  // Blue is ON
            end
            MAGENTA: begin
                next_red = 1'b1;  // Red is ON
                next_blue = 1'b1;  // Blue is ON (Magenta is a mix of red and blue)
            end
            default: begin
                next_red = 1'b0;
                next_green = 1'b0;
                next_blue = 1'b0;
            end
        endcase
    end

    // Sequential block to handle state transitions and counter for timing
    always_ff @(posedge clk) begin
        // Update current state based on next state
        current_state <= next_state;

        // Update color outputs based on current state
        RGB_R <= next_red;
        RGB_G <= next_green;
        RGB_B <= next_blue;

        // Count to control the timing for each color change
        count <= (count + 1) % CLK_CYCLE;

        // State transitions based on count
        if (count == CLK_CYCLE / 6) begin
            next_state = YELLOW;
        end
        else if (count == 2 * CLK_CYCLE / 6) begin
            next_state = GREEN;
        end
        else if (count == 3 * CLK_CYCLE / 6) begin
            next_state = CYAN;
        end
        else if (count == 4 * CLK_CYCLE / 6) begin
            next_state = BLUE;
        end
        else if (count == 5 * CLK_CYCLE / 6) begin
            next_state = MAGENTA;
        end
        else if (count == CLK_CYCLE - 1) begin
            next_state = RED;  // Reset to RED when the cycle completes
        end
    end

endmodule
