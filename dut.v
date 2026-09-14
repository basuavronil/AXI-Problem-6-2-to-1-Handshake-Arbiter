// ============================================================================
// Module      : handshake_arbiter_2to1
// Description : Fixed-priority 2-to-1 handshake arbiter with internal lock register.
// Protocol    : Valid / Ready (Handshake occurs when Valid && Ready == 1)
// Priority    : Channel A (High) > Channel B (Low)
// Standard    : Verilog-2001
// ============================================================================

module handshake_arbiter_2to1 (
    input  wire        clk,
    input  wire        rst_n,

    // Upstream Producer A (High Priority)
    input  wire [31:0] i_data_a,
    input  wire        i_valid_a,
    output wire        o_ready_a,

    // Upstream Producer B (Low Priority)
    input  wire [31:0] i_data_b,
    input  wire        i_valid_b,
    output wire        o_ready_b,

    // Downstream Consumer Output
    output wire [31:0] o_data_out,
    output wire        o_valid_out,
    input  wire        i_ready_out
);

    // ------------------------------------------------------------------------
    // Internal Registers & Wires
    // ------------------------------------------------------------------------
    reg  r_lock;        // 1'b1 = Lock active during backpressure stall
    reg  r_owner;       // 1'b0 = Producer A, 1'b1 = Producer B
    reg  active_owner;  // 1'b0 = Producer A, 1'b1 = Producer B

    wire handshake_complete;

    // ------------------------------------------------------------------------
    // Combinational Selection Logic
    // ------------------------------------------------------------------------
    always @(*) begin
        if (r_lock) begin
            // Lock active: Preserve owner until handshake completes
            active_owner = r_owner;
        end else begin
            // Lock inactive: Channel A takes precedence over Channel B
            if (i_valid_a) begin
                active_owner = 1'b0;
            end else begin
                active_owner = 1'b1;
            end
        end
    end

    // Muxing Data and Valid outputs
    assign o_data_out  = (active_owner == 1'b0) ? i_data_a  : i_data_b;
    assign o_valid_out = (active_owner == 1'b0) ? i_valid_a : i_valid_b;

    // Demuxing Ready backpressure signal
    assign o_ready_a   = (active_owner == 1'b0) ? i_ready_out : 1'b0;
    assign o_ready_b   = (active_owner == 1'b1) ? i_ready_out : 1'b0;

    // ------------------------------------------------------------------------
    // Lock Register Sequential Logic
    // ------------------------------------------------------------------------
    assign handshake_complete = o_valid_out && i_ready_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_lock  <= 1'b0;
            r_owner <= 1'b0;
        end else begin
            if (handshake_complete) begin
                // Transaction complete: Release lock
                r_lock <= 1'b0;
            end else if (o_valid_out && !i_ready_out) begin
                // Consumer stalled: Lock bus to prevent preemption mid-transaction
                r_lock  <= 1'b1;
                r_owner <= active_owner;
            end
        end
    end

endmodule
