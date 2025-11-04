`ifndef CONTROLLER_SV
`define CONTROLLER_SV

module controller (
    input  logic clk, 
    output logic load_sreg, 
    output logic transmit_pixel, 
    output logic [5:0] pixel, 
    output logic [4:0] frame
);

    localparam TRANSMIT_FRAME       = 1'b0;
    localparam IDLE                 = 1'b1;

    localparam [2:0] READ_CH_VALS   = 3'b001;
    localparam [2:0] LOAD_SREG      = 3'b010;
    localparam [2:0] TRANSMIT_PIXEL = 3'b100;

    localparam [8:0]  TRANSMIT_CYCLES = 9'd360;     // = 24 bits / pixel × 15 cycles / bit
    localparam [19:0] IDLE_CYCLES      = 20'd750000; // 15 fps

    logic state = TRANSMIT_FRAME;   
    logic next_state;

    logic [2:0] transmit_phase = READ_CH_VALS;
    logic [2:0] next_transmit_phase;

    logic [5:0]  pixel_counter   = 6'd0;
    logic [4:0]  frame_counter   = 5'd0;
    logic [8:0]  transmit_counter = 9'd0;
    logic [19:0] idle_counter     = 20'd0;

    logic transmit_pixel_done;
    logic idle_done;

    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1);
    assign idle_done           = (idle_counter == IDLE_CYCLES - 1);

    always_ff @(negedge clk) begin
        state           <= next_state;
        transmit_phase  <= next_transmit_phase;
    end

    always_comb begin
        next_state = 1'bx;
        unique case (state)
            TRANSMIT_FRAME:
                if ((pixel_counter == 6'd63) && transmit_pixel_done)
                    next_state = IDLE;
                else
                    next_state = TRANSMIT_FRAME;
            IDLE:
                if (idle_done)
                    next_state = TRANSMIT_FRAME;
                else
                    next_state = IDLE;
        endcase
    end

    always_comb begin
        next_transmit_phase = READ_CH_VALS;
        if (state == TRANSMIT_FRAME) begin
            case (transmit_phase)
                READ_CH_VALS:   next_transmit_phase = LOAD_SREG;
                LOAD_SREG:      next_transmit_phase = TRANSMIT_PIXEL;
                TRANSMIT_PIXEL: next_transmit_phase = transmit_pixel_done ? READ_CH_VALS : TRANSMIT_PIXEL;
            endcase
        end
    end

    always_ff @(negedge clk)
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done)
            pixel_counter <= pixel_counter + 1;

    always_ff @(negedge clk)
        if (idle_done)
            frame_counter <= frame_counter + 1;

    always_ff @(negedge clk)
        if (transmit_phase == TRANSMIT_PIXEL)
            transmit_counter <= transmit_counter + 1;
        else
            transmit_counter <= 9'd0;

    always_ff @(negedge clk)
        if (state == IDLE)
            idle_counter <= idle_counter + 1;
        else
            idle_counter <= 20'd0;

    assign pixel          = pixel_counter;
    assign frame          = frame_counter;
    assign load_sreg      = (transmit_phase == LOAD_SREG);
    assign transmit_pixel = (transmit_phase == TRANSMIT_PIXEL);

endmodule

`endif // CONTROLLER_SV
