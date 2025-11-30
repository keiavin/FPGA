module fir_siso (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] din,
    output reg signed [31:0] dout
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

    // Internal wires for multiplication results
    wire signed [31:0] mult[0:7];

    // Transpose FIR Registers (Accumulators)
    reg signed [31:0] acc[0:6];

    // Multiplication
    assign mult[0] = din * H0;
    assign mult[1] = din * H1;
    assign mult[2] = din * H2;
    assign mult[3] = din * H3;
    assign mult[4] = din * H4;
    assign mult[5] = din * H5;
    assign mult[6] = din * H6;
    assign mult[7] = din * H7;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc[0] <= 32'd0;
            acc[1] <= 32'd0;
            acc[2] <= 32'd0;
            acc[3] <= 32'd0;
            acc[4] <= 32'd0;
            acc[5] <= 32'd0;
            acc[6] <= 32'd0;
            dout   <= 32'd0;
        end else begin
            // Transpose structure accumulation
            acc[0] <= mult[7];
            acc[1] <= mult[6] + acc[0];
            acc[2] <= mult[5] + acc[1];
            acc[3] <= mult[4] + acc[2];
            acc[4] <= mult[3] + acc[3];
            acc[5] <= mult[2] + acc[4];
            acc[6] <= mult[1] + acc[5];

            // Final output (registered for better timing)
            dout   <= mult[0] + acc[6];
        end
    end

endmodule
