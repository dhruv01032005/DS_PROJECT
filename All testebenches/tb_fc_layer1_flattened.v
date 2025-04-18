`timescale 1ns / 1ps

module tb_fc_layer1_flattened;
    parameter IN_SIZE  = 16;
    parameter OUT_SIZE = 8;
    parameter W = 8; // coe bits
    parameter ACC_WIDTH = W+10;

    reg clk;
//    reg reset;
    reg start;
    
    // flatten the vectors and matrices
    reg signed [W*IN_SIZE-1:0] in_vector_flat;
    reg signed [W*(OUT_SIZE*IN_SIZE)-1:0] weights_flat;
    reg signed [W*OUT_SIZE-1:0] biases_flat;
    wire signed [W*OUT_SIZE-1:0] out_vector_flat;
    
    wire done;

    // module instance
    fc_layer1_flattened #(
        .IN_SIZE(IN_SIZE),
        .OUT_SIZE(OUT_SIZE),
        .W(W),
        .ACC_WIDTH(ACC_WIDTH)
    ) DUT (
        .clk(clk),
//        .reset(reset),
        .start(start),
        .in_vector_flat(in_vector_flat),
        .weights_flat(weights_flat),
        .biases_flat(biases_flat),
        .out_vector_flat(out_vector_flat),
        .done(done)
    );

    // clk
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    integer i, j;
    initial begin
//        reset = 1;
        start = 0;
        #15;
//        reset = 0;
        #10;
        
        // sample input vector
        for (i = 0; i < IN_SIZE; i = i + 1) begin
            in_vector_flat[i*W +: W] = i + 1;
        end

        // sample weight matrix
        for (i = 0; i < OUT_SIZE; i = i + 1) begin
            for (j = 0; j < IN_SIZE; j = j + 1) begin
                case (j % 4)
                    0: weights_flat[(i*IN_SIZE + j)*W +: W] = 8'sd1;
                    1: weights_flat[(i*IN_SIZE + j)*W +: W] = 8'sd1;
                    2: weights_flat[(i*IN_SIZE + j)*W +: W] = -8'sd1;
                    3: weights_flat[(i*IN_SIZE + j)*W +: W] = 8'sd0;
                    default: weights_flat[(i*IN_SIZE + j)*W +: W] = 8'sd0;
                endcase
            end
        end
        
        for (i = 0; i < OUT_SIZE; i = i + 1) begin 
                biases_flat[i*W +: W] = -8'sd14 + i*8'sd4;
        end
    
            #10;
            start = 1;
            #10;
        start = 0;
        wait (done == 1);
        #10;
        
        // print statements
        $display("Output vector:");
        for (i = 0; i < OUT_SIZE; i = i + 1) begin
            $display("Neuron %0d: %d", i, $signed(out_vector_flat[i*W +: W]));
        end
        
        $finish;
    end
endmodule