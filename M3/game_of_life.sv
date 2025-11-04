`ifndef GAME_OF_LIFE_SV
`define GAME_OF_LIFE_SV

`ifdef USE_SIMPLE_GOL
// --- SIMPLE STUB VERSION ---
module game_of_life (
    input  logic clk,
    input  logic reset,
    input  logic start,
    input  logic [63:0] cur_bits,
    output logic [63:0] next_bits,
    output logic done
);
    // just pass through the same pattern
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            next_bits <= 64'd0;
            done <= 1'b0;
        end else if (start) begin
            next_bits <= cur_bits;
            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
endmodule
`else
// --- FULL GAME OF LIFE IMPLEMENTATION ---
module game_of_life #(
    parameter [8:0] S_MASK = 9'b000001100, // neighbors 2 or 3 survive
    parameter [8:0] B_MASK = 9'b000001000  // neighbors 3 are born
)(
    input         clk,
    input         reset,
    input         start,
    input  [63:0] cur_bits,
    output [63:0] next_bits,
    output        done
);

    reg         running;
    reg  [5:0]  idx;
    reg [63:0]  snapshot;
    reg [63:0]  next_accum;
    reg         done_r;

    assign next_bits = next_accum;
    assign done      = done_r;

    function [3:0] nbrs;
        input integer i;
        input [63:0] m;
        integer row, col, dx, dy, rr, cc, count;
        begin
            row = i / 8;
            col = i % 8;
            count = 0;
            for (dx = -1; dx <= 1; dx = dx + 1)
                for (dy = -1; dy <= 1; dy = dy + 1)
                    if (!(dx == 0 && dy == 0)) begin
                        rr = (row + dx + 8) % 8;
                        cc = (col + dy + 8) % 8;
                        count = count + m[rr*8 + cc];
                    end
            nbrs = count[3:0];
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            running   <= 1'b0;
            idx       <= 6'd0;
            snapshot  <= 64'b0;
            next_accum<= 64'b0;
            done_r    <= 1'b0;
        end else begin
            done_r <= 1'b0;

            if (!running) begin
                if (start) begin
                    running    <= 1'b1;
                    idx        <= 6'd0;
                    snapshot   <= cur_bits;
                    next_accum <= 64'b0;
                end
            end else begin
                reg alive;
                reg [3:0] n;
                reg next_bit;

                alive    = snapshot[idx];
                n        = nbrs(idx, snapshot);
                next_bit = alive ? S_MASK[n] : B_MASK[n];
                next_accum[idx] <= next_bit;

                if (idx == 6'd63) begin
                    running <= 1'b0;
                    done_r  <= 1'b1;
                end else
                    idx <= idx + 6'd1;
            end
        end
    end
endmodule
`endif

`endif // GAME_OF_LIFE_SV
