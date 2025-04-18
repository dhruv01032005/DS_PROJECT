`timescale 1ns / 1ps

module relu_layer01 #(
    parameter W = 8,          
    parameter LAYER = 10
)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [LAYER*W-1:0] data_in,
    output reg valid_out,
    output reg [LAYER*W-1:0] data_out   
); 
    
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out <= {(LAYER*W){1'b0}};
        end else begin
            valid_out <= valid_in;
            
            for (i = 0; i < LAYER; i = i + 1) begin

                if (data_in[i*W + (W-1)] == 1'b1) begin
                    data_out[i*W +: W] <= {W{1'b0}};
                end else begin
                    data_out[i*W +: W] <= data_in[i*W +: W];
                end
            end
        end
    end

endmodule