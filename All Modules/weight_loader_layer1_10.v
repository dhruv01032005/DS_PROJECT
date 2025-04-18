`timescale 1ns / 1ps

module weight_loader_layer1_10 #(
    parameter IN_SIZE  = 1152,
    parameter OUT_SIZE = 8,
    parameter W = 8,
    parameter TOTAL_WEIGHTS = IN_SIZE * OUT_SIZE,
    parameter ADDR_WIDTH = 18
)(
    input clk,      // System clock
    input start,    // Start signal to start
    output reg [(TOTAL_WEIGHTS*W)-1:0] data_out, // Bit from the bram
    output done
);

    // BRAM Signals
    reg bram_en;
    reg bram_ren;
    reg [ADDR_WIDTH-1:0] bram_addr;
    wire [W-1:0] bram_dout;

    // Control signals
    reg [ADDR_WIDTH:0] read_counter;
    reg [ADDR_WIDTH:0] write_ptr;
    reg [1:0] state;
    
    // FSM states
    localparam INITIAL  = 2'b00;
    localparam READ  = 2'b01;
    localparam DONE  = 2'b10;

    // BRAM Call
    BRAM bram_inst (
        .clk(clk),
        .en(bram_en),
        .ren(bram_ren),
        .wen(1'b0),  // Read-only
        .addr(bram_addr),
        .din(8'b0),
        .dout(bram_dout)
    );
    
    
    // Initialization
    initial begin
        state <= INITIAL;
        bram_en <= 0;
        bram_ren <= 0;
        bram_addr <= 82944;
        read_counter <= 0;
        write_ptr <= 0;
        data_out <= 0;
    end
    
    // Main FSM
    always @(posedge clk) begin
        case (state)
            INITIAL: begin
                if (start) begin
                    state <= READ;
                    bram_en <= 1;
                    bram_ren <= 1;
                    bram_addr <= 82944;
                    read_counter <= 0;
                end
            end

            READ: begin
                if (read_counter <= TOTAL_WEIGHTS-1) begin
                    bram_addr <= bram_addr + 1;
                    read_counter <= read_counter + 1;
                end
                else begin
                    state <= DONE;
                    bram_ren <= 0;
                end

                // Store data with 2-cycle delay
                if (read_counter >= 2) begin
                    data_out[write_ptr*W +: W] <= bram_dout;
                    write_ptr <= write_ptr + 1;
                end
            end

            DONE: begin
                // Handle last two elements of the bram
                if (write_ptr < TOTAL_WEIGHTS) begin
                    data_out[write_ptr*W +: W] <= bram_dout;
                    write_ptr <= write_ptr + 1;
                end
                else begin
                    bram_en <= 0;
                end
            end
        endcase
    end

    // Assign done
    assign done = (state == DONE) && (write_ptr == TOTAL_WEIGHTS);

endmodule