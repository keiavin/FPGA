module fir_parallel (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] din0,
    input wire signed [15:0] din1,
    input wire signed [15:0] din2,
    input wire signed [15:0] din3,
    input wire signed [15:0] din4,
    input wire signed [15:0] din5,
    output reg signed [31:0] dout0,
    output reg signed [31:0] dout1,
    output reg signed [31:0] dout2,
    output reg signed [31:0] dout3,
    output reg signed [31:0] dout4,
    output reg signed [31:0] dout5
);

    // Coefficients (Q1.15)
    localparam signed [15:0] H0 = -347;
    localparam signed [15:0] H1 = 1078;
    localparam signed [15:0] H2 = 1011;
    localparam signed [15:0] H3 = -6129;
    localparam signed [15:0] H4 = -917;
    localparam signed [15:0] H5 = 20673;
    localparam signed [15:0] H6 = 23424;
    localparam signed [15:0] H7 = 7549;

    // Registers to store previous inputs (History)
    // We need enough history for 8 taps.
    // Max delay is 7 samples.
    // Each clock brings 6 samples.
    // So we need the previous block (indexes -1 to -6)
    // and part of the block before that (indexes -7)

    reg signed [15:0] prev_din [0:5];   // Stores din at t-1
    reg signed [15:0] prev2_din [0:5];  // Stores din at t-2

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_din[0] <= 0; prev_din[1] <= 0; prev_din[2] <= 0;
            prev_din[3] <= 0; prev_din[4] <= 0; prev_din[5] <= 0;
            prev2_din[0] <= 0; prev2_din[1] <= 0; prev2_din[2] <= 0;
            prev2_din[3] <= 0; prev2_din[4] <= 0; prev2_din[5] <= 0;

            dout0 <= 0; dout1 <= 0; dout2 <= 0;
            dout3 <= 0; dout4 <= 0; dout5 <= 0;
        end else begin
            // Update history
            prev_din[0] <= din0; prev_din[1] <= din1; prev_din[2] <= din2;
            prev_din[3] <= din3; prev_din[4] <= din4; prev_din[5] <= din5;

            prev2_din[0] <= prev_din[0]; prev2_din[1] <= prev_din[1]; prev2_din[2] <= prev_din[2];
            prev2_din[3] <= prev_din[3]; prev2_din[4] <= prev_din[4]; prev2_din[5] <= prev_din[5];

            // Compute Outputs (Registered Output)
            // The logic below calculates the convolution sum for each parallel channel.
            // Note: dinX is current sample x[6k+X]

            // dout0 corresponding to x[6k]
            // y[6k] = h0*x[6k] + h1*x[6k-1] + ... + h7*x[6k-7]
            // x[6k]   is din0
            // x[6k-1] is prev_din[5]
            // x[6k-2] is prev_din[4]
            // ...
            // x[6k-6] is prev_din[0]
            // x[6k-7] is prev2_din[5]
            dout0 <= (din0 * H0) + (prev_din[5] * H1) + (prev_din[4] * H2) + (prev_din[3] * H3) +
                     (prev_din[2] * H4) + (prev_din[1] * H5) + (prev_din[0] * H6) + (prev2_din[5] * H7);

            // dout1 corresponding to x[6k+1]
            // y[6k+1] = h0*x[6k+1] + h1*x[6k] + ...
            // x[6k+1] is din1
            // x[6k]   is din0
            // x[6k-1] is prev_din[5]
            // ...
            dout1 <= (din1 * H0) + (din0 * H1) + (prev_din[5] * H2) + (prev_din[4] * H3) +
                     (prev_din[3] * H4) + (prev_din[2] * H5) + (prev_din[1] * H6) + (prev_din[0] * H7);

            // dout2 corresponding to x[6k+2]
            dout2 <= (din2 * H0) + (din1 * H1) + (din0 * H2) + (prev_din[5] * H3) +
                     (prev_din[4] * H4) + (prev_din[3] * H5) + (prev_din[2] * H6) + (prev_din[1] * H7);

            // dout3 corresponding to x[6k+3]
            dout3 <= (din3 * H0) + (din2 * H1) + (din1 * H2) + (din0 * H3) +
                     (prev_din[5] * H4) + (prev_din[4] * H5) + (prev_din[3] * H6) + (prev_din[2] * H7);

            // dout4 corresponding to x[6k+4]
            dout4 <= (din4 * H0) + (din3 * H1) + (din2 * H2) + (din1 * H3) +
                     (din0 * H4) + (prev_din[5] * H5) + (prev_din[4] * H6) + (prev_din[3] * H7);

            // dout5 corresponding to x[6k+5]
            dout5 <= (din5 * H0) + (din4 * H1) + (din3 * H2) + (din2 * H3) +
                     (din1 * H4) + (din0 * H5) + (prev_din[5] * H6) + (prev_din[4] * H7);
        end
    end

endmodule
