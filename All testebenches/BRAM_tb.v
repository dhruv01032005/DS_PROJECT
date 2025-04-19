`timescale 1ns / 1ps

module BRAM_tb();
reg clk, en, wen, ren;
reg [14:0] addr;
reg [7:0] din;
wire [7:0] dout;

BRAM memory(.clk(clk),.en(en),.ren(ren),.wen(wen),.addr(addr),.din(din),.dout(dout));

initial begin
    clk <= 1;
    // clock cycle = 2ns
    forever #1 clk <= ~clk;
end

initial begin
    
    // INITIALIZATION
    en <= 0; ren <= 0; wen <= 0; addr <= 0; din <= 8'hff; 
    #10;
    
    // ENABLE BRAM
    // just enabling the bram, no mem operation performed as ren = 0 and wen = 0
    en <= 1; 
    #10;
    
    // READ: CASE 1 (ren changes from 0 to 1 and addr also changes at posedge clk)
    // read data at addr 6 which stores 00000101 as data
    // 2 clock cycle delay observed => dout valid only after 4ns delay (clock cycle = 2ns, total time = 2 * 2ns = 4ns)
    // hence, 00000101 must observed at (20 + 4)ns = 24ns
    // to read: ensure en = 1, ren = 1, wen = 0 and addr is valid (within the pre-defined address range)
    // data gets collected in dout wire
    ren <= 1; addr <= 11;
    #10;
    
    // DISABLE BRAM
    // disable bram, addr changed to 0 which stores 00001111 as data
    // disabling bram <=> en = 0, no mem operation performed (ren = 0 and wen = 0)
    // notice that changing addr when en = 0 does not affect dout as no mem operation is performed
    // notice that dout holds the last value read
    en <= 0; addr <= 0;
    #10;
    
    // READ: CASE 1 (ren changes from 0 to 1 and addr also changes at posedge clk)
    // read data at addr 7 which stores 00000011 as data
    // notice that between 42ns (40 + 1*2)ns and 44ns (40 + 2*2)ns, dout changes to 00001111 momentarily
    // which is actually the data stored at addr 0 (the previous value of addr just before changing it below)
    // valid data (which is 00000011) appears at dout only after two clock cycles, i.e., after 44ns
    en <= 1; ren <= 1; addr <= 7; 
    #10;
    
    // READ: CASE 2 (ren = 1 remains as it is, only addr changesat posedge clk)
    // read data at addr 8 which stores 00000000 as data
    // notice that between 50ns and 52ns (50 + 1*2)ns, dout retains its previous value of 00000011
    // which is actually the data stored at addr 7 (the previous value of addr just before changing it below)
    // valid data (which is 00000000) appears at dout after ONE clock cycle, i.e., after 52ns
    // interestingly, here the data appears after a delay of 1 CLOCK CYCLE instead of 2 CYCLES as observed in previous cases
    // more on this in BRAM_tb2 testbench; play around and see if you can identify a pattern :)
    en <= 1; ren <= 1; addr <= 8; 
    #10;
    
    //DISABLE BRAM
    // Psssst: You don't actually need to disable BRAM here but it is fine!!!
    en <= 0; ren <= 0; addr <= 8;
    #10;
    
    // WRITE (wen changes from 0 to 1 and addr also changes at posedge clk)
    // write data 00000000 at addr 0 which previously stored 00001111
    // quite similar to read operation with its confusing hidden working
    // notice that after 2 clock cycles from write, dout guaranteed changes to the newly written value
    // more on this in BRAM_tb2 testbench; play around and see if you can identify a pattern :)
    en <= 1; ren <= 0; wen <= 1; addr <= 0; din <= 8'hff;
    #10;
    
    $finish();
end

endmodule
