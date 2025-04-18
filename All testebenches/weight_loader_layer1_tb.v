`timescale 1ns / 1ps

module weight_loader_layer1_tb;

    // Parameters (match DUT)
    parameter IN_SIZE = 3;
    parameter OUT_SIZE = 2;
    parameter W = 8;
    parameter TOTAL_WEIGHTS = IN_SIZE * OUT_SIZE;
    parameter ADDR_WIDTH = 18;
    
    // Signals
    reg clk;
    reg start;
    wire [(TOTAL_WEIGHTS*W)-1:0] data_out;
    wire done;
    
    
    // Instantiate DUT
    weight_loader_layer1_1 #(
        .IN_SIZE(IN_SIZE),
        .OUT_SIZE(OUT_SIZE),
        .W(W)
    ) dut (
        .clk(clk),
        .start(start),
        .data_out(data_out),
        .done(done)
    );
    
    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 100MHz clock
    end
    
    // Main test sequence
    initial begin
        start = 1'b1;
        #100;
        
    end
    
endmodule