`ifndef MEMORY_SV
`define MEMORY_SV

`ifdef USE_SIMPLE_MEM
// --- SIMPLE MEMORY VERSION (optional stub) ---
module memory (
    input  logic clk,
    input  logic reset,
    input  logic [5:0]  read_address,
    output logic        read_bit,
    input  logic        apply_next,
    input  logic [63:0] next_bits,
    output logic [63:0] cur_bits
);
    // Simple fixed memory model for testing
    always_ff @(posedge clk or posedge reset) begin
        if (reset)           cur_bits <= 64'd0;
        else if (apply_next) cur_bits <= next_bits;
    end
    always_ff @(posedge clk)
        read_bit <= cur_bits[read_address];
endmodule
`else
// --- FULL MEMORY IMPLEMENTATION ---
module memory #(
    parameter int SEED_ID = 0   // 0=glider, 1=blinker, 2=block
)(
    input  logic        clk,
    input  logic        reset,          // load seed on reset pulse
    input  logic [5:0]  read_address,
    output logic        read_bit,
    input  logic        apply_next,
    input  logic [63:0] next_bits,
    output logic [63:0] cur_bits
);
    // SEED_1: glider (bottom-left-ish)
    localparam [63:0] SEED_1 =
    64'b00000000_00000000_00000000_00000000_00000000_01110000_00010000_00100000;

    // SEED_2: blinker (period-2)
    localparam [63:0] SEED_2 =
    64'b00000000_00011100_00000000_00000000_00000000_00000000_00000000_00000000;

    // SEED_3: toad (period-2)
    localparam [63:0] SEED_3 =
    64'b00000000_00000000_00000000_00000000_00111000_00011100_00000000_00000000;

    logic [63:0] seed;
    always_comb begin
        unique case (SEED_ID)
            1: seed = SEED_2;
            2: seed = SEED_3;
            default: seed = SEED_1;
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)           cur_bits <= seed;
        else if (apply_next) cur_bits <= next_bits;
    end

    always_ff @(posedge clk)
        read_bit <= cur_bits[read_address];
endmodule
`endif

`endif // MEMORY_SV
