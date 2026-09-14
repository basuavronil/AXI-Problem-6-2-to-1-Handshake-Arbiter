// ============================================================================
// Module      : tb_handshake_arbiter_2to1
// Description : Self-checking Verilog-2001 testbench for 2-to-1 Handshake Arbiter
// ============================================================================

`timescale 1ns/1ps

module tb_handshake_arbiter_2to1;

    // DUT Signals
    reg        clk;
    reg        rst_n;

    reg [31:0] i_data_a;
    reg        i_valid_a;
    wire       o_ready_a;

    reg [31:0] i_data_b;
    reg        i_valid_b;
    wire       o_ready_b;

    wire [31:0] o_data_out;
    wire        o_valid_out;
    reg         i_ready_out;

    // Test Tracking
    integer pass_count;
    integer fail_count;

    // Instantiate DUT
    handshake_arbiter_2to1 dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .i_data_a   (i_data_a),
        .i_valid_a  (i_valid_a),
        .o_ready_a  (o_ready_a),
        .i_data_b   (i_data_b),
        .i_valid_b  (i_valid_b),
        .o_ready_b  (o_ready_b),
        .o_data_out (o_data_out),
        .o_valid_out(o_valid_out),
        .i_ready_out(i_ready_out)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // Helper Task for Verification
    task check_handshake;
        input [31:0] exp_data;
        input [256:1] test_name;
        begin
            if (o_valid_out && i_ready_out) begin
                if (o_data_out === exp_data) begin
                    $display("[PASS] %s | Captured Data: 0x%8h", test_name, o_data_out);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL] %s | Expected: 0x%8h, Got: 0x%8h", test_name, exp_data, o_data_out);
                    fail_count = fail_count + 1;
                end
            end
        end
    endtask

    // Test Stimulus
    initial begin
        // Initialize
        clk        = 0;
        rst_n      = 0;
        i_data_a   = 32'h0;
        i_valid_a  = 1'b0;
        i_data_b   = 32'h0;
        i_valid_b  = 1'b0;
        i_ready_out= 1'b0;
        pass_count = 0;
        fail_count = 0;

        // Reset Sequence
        #20;
        rst_n = 1'b1;
        @(posedge clk);
        $display("\n--- Starting 2-to-1 Handshake Arbiter Tests ---");

        // TEST 1: Simultaneous Requests (Priority Check: A > B)
        $display("\n[TEST 1] Simultaneous Requests (Channel A Priority)");
        i_data_a    = 32'hAAAA_0001;
        i_valid_a   = 1'b1;
        i_data_b    = 32'hBBBB_0001;
        i_valid_b   = 1'b1;
        i_ready_out = 1'b1;

        @(posedge clk);
        #1; // Sample post-clock edge
        check_handshake(32'hAAAA_0001, "Test 1 - Priority Channel A");

        // Clear A, keep B valid for next transfer
        i_valid_a = 1'b0;

        @(posedge clk);
        #1;
        check_handshake(32'hBBBB_0001, "Test 1 - Service Channel B");

        i_valid_b   = 1'b0;
        i_ready_out = 1'b0;

        // TEST 2: Backpressure Lock Verification
        $display("\n[TEST 2] Backpressure Lock Verification");
        i_data_b    = 32'hBBBB_0002;
        i_valid_b   = 1'b1;
        i_ready_out = 1'b0; // Consumer stalled

        @(posedge clk); // B claims ownership, r_lock becomes 1

        // High priority Channel A asserts during B's stall
        i_data_a  = 32'hAAAA_0002;
        i_valid_a = 1'b1;

        @(posedge clk);
        i_ready_out = 1'b1; // Consumer releases backpressure
        #1;
        check_handshake(32'hBBBB_0002, "Test 2 - B completes first (Locked)");

        @(posedge clk);
        #1;
        check_handshake(32'hAAAA_0002, "Test 2 - A completes after B lock released");

        // Clean up
        i_valid_a   = 1'b0;
        i_valid_b   = 1'b0;
        i_ready_out = 1'b0;

        // Final Summary
        #20;
        $display("\n==============================================");
        $display(" TEST SUMMARY: PASS = %0d | FAIL = %0d", pass_count, fail_count);
        $display("==============================================\n");

        if (fail_count == 0) begin
            $display(">>> ALL TESTS PASSED SUCCESSFULLY! <<<\n");
        end else begin
            $display(">>> TEST SUITE FAILED! <<<\n");
        end

        $finish;
    end

endmodule
