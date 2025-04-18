`timescale 1ns / 1ps

module BRAM(clk, en, ren, wen, addr, din, dout);
input clk, en, wen, ren;
input [17:0] addr;
input [7:0] din;
output [7:0] dout;
    BRAM_ALL inst1(.clka(clk),.ena((en&ren)|(en&wen)),.wea(wen),.addra(addr),.dina(din),.douta(dout));
endmodule
