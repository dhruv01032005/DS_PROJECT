`timescale 1ns / 1ps

module relu_layer01_tb();

    parameter W = 8;
    parameter LAYER = 10;

    reg clk;
    reg rst;
    reg valid_in;
    reg [LAYER*W-1:0] data_in;
    wire valid_out;
    wire [LAYER*W-1:0] data_out;
    
    integer i;
    
    relu_layer01 #(
        .W(W),
        .LAYER(LAYER)
    ) uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .data_out(data_out)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end
    
    initial begin
        rst = 1; valid_in = 0; data_in = {(LAYER*W){1'b0}}; #20;
        
        rst = 0; #10;
        
        for (i = 0; i < LAYER; i = i + 1) begin
            if (i % 4 == 0)
                data_in[i*W +: W] = 8'b00100011;  // Positive value
            else if (i % 4 == 1)
                data_in[i*W +: W] = 8'b10000000;  // Negative value (MSB=1)
            else if (i % 4 == 2)
                data_in[i*W +: W] = 8'b01111111;  // Maximum positive
            else
                data_in[i*W +: W] = 8'b00000000;  // Zero
        end
        
        valid_in = 1; #10;
        
        for (i = 0; i < LAYER; i = i + 1) begin
            if (i % 2 == 0)
                data_in[i*W +: W] = 8'b01010110;  // Positive value
            else
                data_in[i*W +: W] = 8'b10110010;  // Negative value (MSB=1)
        end
    end

endmodule