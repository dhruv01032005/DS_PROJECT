`timescale 1ns / 1ps

module fc_layer1_flattened #(
    parameter IN_SIZE  = 64,
    parameter OUT_SIZE = 8,
    parameter W = 8,
    parameter ACC_WIDTH = W+7
)(
    input clk,
    input start,
    // flattened vectors and matrices
    input signed [W*IN_SIZE-1:0] in_vector_flat,
    input signed [W*(OUT_SIZE*IN_SIZE)-1:0] weights_flat,
    input signed [W*OUT_SIZE-1:0] biases_flat,
    output reg signed [W*OUT_SIZE-1:0] out_vector_flat, 
    output reg done
);
    reg reset = 1;
    // used to check for overflow
    localparam MAX_POS = (2 ** (W-1)) - 1;
    wire signed [W-1:0] biases [0:OUT_SIZE-1];
    
    // generating bias instances
    genvar i;
    generate
        for (i = 0; i < OUT_SIZE; i = i + 1) begin : UNPACK_BIASES
            assign biases[i] = biases_flat[i*W +: W];
        end
    endgenerate

    // generating weight matrix instances
    wire signed [W*IN_SIZE-1:0] weight_rows [0:OUT_SIZE-1];
    genvar n;
    generate
        for (n = 0; n < OUT_SIZE; n = n + 1) begin : UNPACK_WEIGHTS
            assign weight_rows[n] = weights_flat[n*IN_SIZE*W +: IN_SIZE*W];
        end
    endgenerate

    // PE instantiation
    wire signed [ACC_WIDTH-1:0] pe_result [0:OUT_SIZE-1];
    wire [OUT_SIZE-1:0] pe_done;

    genvar p;
    generate
        for (p = 0; p < OUT_SIZE; p = p + 1) begin : PE_INSTANCES
            PE_seq_flat #(IN_SIZE, W, ACC_WIDTH) pe_inst (
                .clk(clk),
                .reset(reset),
                .start(start),
                .in_vector_flat(in_vector_flat),
                .weight_row_flat(weight_rows[p]),
                .bias(biases[p]),
                .result(pe_result[p]),
                .done(pe_done[p])
            );
        end
    endgenerate

    // combining output of all neurons
    integer j;
    always @(posedge clk) begin
        if (reset) begin
            if (!done)
                reset = 0;
            out_vector_flat <= 0;
            done <= 0;
    
        end else if (&pe_done) begin
            for (j = 0; j < OUT_SIZE; j = j + 1) begin
                if ($signed(pe_result[j]) > 0) begin
                    // overflow check 
                    if (pe_result[j] > MAX_POS)
                        out_vector_flat[j*W +: W] <= MAX_POS;
                    
                    // relu
                    else
                        out_vector_flat[j*W +: W] <= pe_result[j][W-1:0];
                end else begin
                    out_vector_flat[j*W +: W] <= 0;
                end
            end
            done <= 1;
        end
    end
endmodule