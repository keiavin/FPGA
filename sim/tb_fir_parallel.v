`timescale 1ns / 1ps

module tb_fir_parallel;

    // Parameters
    localparam CLK_PERIOD = 10;
    localparam SIM_TIME = 2000;

    // Inputs/Outputs
    reg clk;
    reg rst_n;
    reg signed [15:0] din [0:5];
    wire signed [31:0] dout [0:5];

    // Instantiate UUT
    fir_parallel uut (
        .clk(clk),
        .rst_n(rst_n),
        .din0(din[0]), .din1(din[1]), .din2(din[2]),
        .din3(din[3]), .din4(din[4]), .din5(din[5]),
        .dout0(dout[0]), .dout1(dout[1]), .dout2(dout[2]),
        .dout3(dout[3]), .dout4(dout[4]), .dout5(dout[5])
    );

    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Sine LUT
    reg signed [15:0] sine_lut [0:19];
    initial begin
        sine_lut[0]  = 0;     sine_lut[1]  = 3090;  sine_lut[2]  = 5878;  sine_lut[3]  = 8090;
        sine_lut[4]  = 9511;  sine_lut[5]  = 10000; sine_lut[6]  = 9511;  sine_lut[7]  = 8090;
        sine_lut[8]  = 5878;  sine_lut[9]  = 3090;  sine_lut[10] = 0;     sine_lut[11] = -3090;
        sine_lut[12] = -5878; sine_lut[13] = -8090; sine_lut[14] = -9511; sine_lut[15] = -10000;
        sine_lut[16] = -9511; sine_lut[17] = -8090; sine_lut[18] = -5878; sine_lut[19] = -3090;
    end

    // Noise Function
    integer noise_seed = 123;
    function signed [15:0] get_noise;
        input integer unused;
        begin
            noise_seed = (noise_seed * 1103515245 + 12345) & 32'h7FFFFFFF;
            get_noise = (noise_seed % 8000) - 4000;
        end
    endfunction

    // History and Driver
    reg signed [15:0] input_history [0:4095];
    integer hist_ptr = 0;
    integer sample_cnt = 0;
    integer i;
    reg signed [15:0] temp_val;

    always @(posedge clk) begin
        if (!rst_n) begin
            for(i=0; i<6; i=i+1) din[i] <= 0;
            hist_ptr = 0;
            sample_cnt = 0;
        end else begin
            // Generate and drive 6 samples
            for(i=0; i<6; i=i+1) begin
                // Generate one value
                temp_val = sine_lut[(sample_cnt + i) % 20] + get_noise(0);

                // Assign to input port
                din[i] <= temp_val;

                // Store in history for verification
                input_history[hist_ptr + i] = temp_val;
            end
            hist_ptr <= hist_ptr + 6;
            sample_cnt <= sample_cnt + 6;
        end
    end

    // Coefficients
    reg signed [15:0] h [0:7];
    initial begin
        h[0] = -347; h[1] = 1078; h[2] = 1011; h[3] = -6129;
        h[4] = -917; h[5] = 20673; h[6] = 23424; h[7] = 7549;
    end

    // Verification
    integer check_cnt = 0;
    integer err_count = 0;
    reg signed [31:0] expected;
    reg signed [31:0] got;
    integer t, k, idx;

    // We start checking after pipeline fills
    // Latency is 1 cycle (6 samples).

    always @(posedge clk) begin
        if (rst_n) begin
            // Wait for 2 cycles of valid data
            if (check_cnt >= 2) begin
                // The current `dout` corresponds to inputs driven `check_cnt-1` cycles ago?
                // Let's trace carefully.
                // Cycle 0 (rst released): Logic drives din (samples 0-5). RTL sees 0.
                // Cycle 1: Logic drives samples 6-11. RTL sees samples 0-5. dout <= Result(0-5).
                // Cycle 2: Logic drives samples 12-17. RTL sees samples 6-11. dout <= Result(6-11).
                //          At Cycle 2 posedge, `dout` holds Result(0-5).
                //          We want to check Result(0-5).
                //          `hist_ptr` has just updated to 12 (at end of cycle 1) -> 18 (at end of cycle 2).
                //          Wait, `hist_ptr` updates non-blocking.
                //          At Cycle 2 posedge (before update), `hist_ptr` is 12 (from cycle 1).
                //          We want to check indices 0-5.
                //          Indices = `hist_ptr` - 12 ? (12-12=0). Yes.

                // Let's verify loop limits.
                for (k = 0; k < 6; k = k + 1) begin
                    // dout[k]
                    got = dout[k];

                    // Calculate expected
                    // Output index = (check_cnt - something) * 6 + k
                    // Let's use `hist_ptr` logic.
                    // verify_base = hist_ptr - 12;
                    // BUT `hist_ptr` is from the *beginning* of the timestep (12).
                    // So we check indices 0..5.
                    idx = (hist_ptr - 12) + k;

                    expected = 0;
                    for (t = 0; t < 8; t = t + 1) begin
                        if (idx - t >= 0)
                            expected = expected + h[t] * input_history[idx - t];
                    end

                    if (got !== expected) begin
                        $display("ERROR at time %t: Sample %0d. Expected %d, Got %d", $time, idx, expected, got);
                        err_count = err_count + 1;
                    end
                end
            end
            check_cnt <= check_cnt + 1;
        end
    end

    // End Simulation
    initial begin
        rst_n = 0;
        #55; // 5.5 cycles
        rst_n = 1;

        #SIM_TIME;

        if (err_count == 0)
            $display("TEST PASSED: All samples matched.");
        else
            $display("TEST FAILED: %d mismatches.", err_count);

        $finish;
    end

    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_fir_parallel);
    end

endmodule
