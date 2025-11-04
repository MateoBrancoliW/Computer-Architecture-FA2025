`include "memory.sv"
`include "game_of_life.sv"
`include "ws2812b.sv"
`include "controller.sv"

module top(
    input  logic clk,
    input  logic SW,     // unused
    input  logic BOOT,   // unused
    output logic _45a
);

    // --- Controller ---
    logic        load_sreg, transmit_pixel;
    logic [5:0]  pixel;
    logic [4:0]  frame;

    controller u_ctrl (
        .clk(clk),
        .load_sreg(load_sreg),
        .transmit_pixel(transmit_pixel),
        .pixel(pixel),
        .frame(frame)
    );

    // --- Shared signals for LED colors ---
    logic [63:0] cur_r, nxt_r, cur_g, nxt_g, cur_b, nxt_b;
    logic rd_r, rd_g, rd_b;
    logic apply_r, apply_g, apply_b;
    logic busy_r, busy_g, busy_b;

    // --- WS2812 driver ---
    logic [23:0] shift_reg;
    logic shift, ws_out;

    ws2812b u_ws (
        .clk(clk),
        .serial_in(shift_reg[23]),
        .transmit(transmit_pixel),
        .ws2812b_out(ws_out),
        .shift(shift)
    );

    // 25% brightness; GRB order
    localparam [7:0] ON = 8'd64;
    always_ff @(posedge clk) begin
        if (load_sreg)
            shift_reg <= { (rd_g ? ON : 8'd0),
                           (rd_r ? ON : 8'd0),
                           (rd_b ? ON : 8'd0) };
        else if (shift)
            shift_reg <= { shift_reg[22:0], 1'b0 };
    end

    assign _45a = ws_out;  // DIN

    // --- Power-on reset ---
    logic [3:0] por = 4'd0;
    always_ff @(posedge clk)
        if (por != 4'hF) por <= por + 1'b1;

    wire rst = (por != 4'hF);

    // --- Frame trigger (detect frame changes) ---
    logic [4:0] frame_d1;
    always_ff @(posedge clk)
        frame_d1 <= frame;

    wire step_pulse = (frame != frame_d1);

    // ==========================
    // RED CHANNEL
    // ==========================
    memory #(.SEED_ID(0)) u_mem_r (
        .clk(clk), .reset(rst),
        .read_address(pixel), .read_bit(rd_r),
        .apply_next(apply_r), .next_bits(nxt_r), .cur_bits(cur_r)
    );

    wire start_r = step_pulse & ~busy_r;
    wire done_r;

    game_of_life u_gol_r (
        .clk(clk), .reset(rst),
        .start(start_r),
        .cur_bits(cur_r),
        .next_bits(nxt_r),
        .done(done_r)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) busy_r <= 1'b0;
        else if (start_r) busy_r <= 1'b1;
        else if (done_r)  busy_r <= 1'b0;
    end

    assign apply_r = done_r;

    // ==========================
    // GREEN CHANNEL
    // ==========================
    memory #(.SEED_ID(1)) u_mem_g (
        .clk(clk), .reset(rst),
        .read_address(pixel), .read_bit(rd_g),
        .apply_next(apply_g), .next_bits(nxt_g), .cur_bits(cur_g)
    );

    wire start_g = step_pulse & ~busy_g;
    wire done_g;

    game_of_life u_gol_g (
        .clk(clk), .reset(rst),
        .start(start_g),
        .cur_bits(cur_g),
        .next_bits(nxt_g),
        .done(done_g)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) busy_g <= 1'b0;
        else if (start_g) busy_g <= 1'b1;
        else if (done_g)  busy_g <= 1'b0;
    end

    assign apply_g = done_g;

    // ==========================
    // BLUE CHANNEL
    // ==========================
    memory #(.SEED_ID(2)) u_mem_b (
        .clk(clk), .reset(rst),
        .read_address(pixel), .read_bit(rd_b),
        .apply_next(apply_b), .next_bits(nxt_b), .cur_bits(cur_b)
    );

    wire start_b = step_pulse & ~busy_b;
    wire done_b;

    game_of_life u_gol_b (
        .clk(clk), .reset(rst),
        .start(start_b),
        .cur_bits(cur_b),
        .next_bits(nxt_b),
        .done(done_b)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) busy_b <= 1'b0;
        else if (start_b) busy_b <= 1'b1;
        else if (done_b)  busy_b <= 1'b0;
    end

    assign apply_b = done_b;

endmodule
