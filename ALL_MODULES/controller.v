`timescale 1ns / 1ps

module controller(
    input clk_100MHz,   // System clock
    input rx,           // UART receive input
    output tx,          // UART transmit output
    output rx_busy,     // UART RX busy flag
    output converted,   // UART RX data converted flag
    output data_valid,  // UART RX data valid flag
    output tx_busy      // UART TX busy flag
);
    
    // MAKING THE STATES FOR FSM
    reg [3:0] state;
    localparam INPUT = 4'b0001, OUTPUT_LAYER_1 = 4'b0010, OUTPUT_LAYER_2 = 4'b0100, FINAL_OUTPUT = 4'b1000;
    
    // General counters
    reg [6:0] input_counter; // 64 needs 7 bits
    reg [3:0] output_counter; // 10 needs 4 bits
    
    // Data storage as flat vectors
    reg [511:0] input_buffer;  // 64 bytes = 64*8 bits
    reg [79:0] output_buffer;   // 10 bytes = 10*8 bits
    wire [4095:0] weight_layer1_1; // 64*8 bytes = 64*8*8 bits
    wire [63:0] bias_layer1_1; // 1*8 bytes = 1*8*8 bits
    wire [4095:0] weight_layer1_2; // 64*8 bytes = 64*8*8 bits
    wire [63:0] bias_layer1_2; // 1*8 bytes = 1*8*8 bits
    wire [1279:0] weight_layer2; // 16*10 bytes = 16*10*8 bits
    wire [79:0] bias_layer2; // 1*10 bytes = 1*10*8 bits
    reg start_1 = 1'b0;
    wire start_2;
    wire start_3;
    wire start_4;
    wire start_5;
    wire start_6;
    wire start_7;
    reg start_8 = 1'b0;
    wire start_9;
    wire start_10;
    wire start_11;
    
    // Data storage of outputs after applying the FCL layer
    wire [63:0] output_layer1_1;
    wire [63:0] output_layer1_2;
    reg [127:0] output_layer1;
    wire [79:0] output_layer2;
    
    // UART signals
    wire [7:0] uart_data;
    reg [7:0] tx_data;
    reg tx_enable;
    reg flush_ctrl;
    reg allow_next;
    
    // UART clock generation
    reg clk_uart;
    reg [4:0] counter;
    
    // UART instances
    uart_rx uart_rx_115200 (
        .rx(rx),
        .i_clk(clk_uart),
        .flush(flush_ctrl),
        .data(uart_data),
        .converted(converted),
        .data_valid(data_valid),
        .busy(rx_busy)
    );
    
    uart_tx uart_tx_115200(
        .clk(clk_uart),
        .tx_enable(tx_enable),
        .data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );
    
    // Initialization block
    initial begin
        counter <= 0;
        clk_uart = 0;
        flush_ctrl <= 0;
        tx_enable <= 0;
        input_buffer <= 512'b0;
        output_buffer <= 80'b1;
        input_counter <= 0;
        output_counter <= 0;
        allow_next <= 0;
        state <= INPUT;
    end

    // Clock divider for UART (115200 baud)
    always @(posedge clk_100MHz) begin
        counter <= counter + 1;
        if(counter == 5'd27) begin
            counter <= 0;
            clk_uart <= ~clk_uart;
        end
    end
    
    weight_loader_layer1_1 w1(
        .clk(clk_100MHz), 
        .start(start_1), 
        .data_out(weight_layer1_1), 
        .done(start_2)
    );
    
    bias_loader_layer1_1 b1(
        .clk(clk_100MHz), 
        .start(start_2), 
        .data_out(bias_layer1_1), 
        .done(start_3)
    );
    
    fc_layer1_flattened m1(
        .clk(clk_100MHz), 
        .start(start_3), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_1), 
        .biases_flat(bias_layer1_1), 
        .out_vector_flat(output_layer1_1), 
        .done(start_4)
    );
    
    weight_loader_layer1_2 w2(
        .clk(clk_100MHz), 
        .start(start_4), 
        .data_out(weight_layer1_2), 
        .done(start_5)
    );
    
    bias_loader_layer1_2 b2(
        .clk(clk_100MHz), 
        .start(start_5), 
        .data_out(bias_layer1_2), 
        .done(start_6)
    );
    
    fc_layer1_flattened m2(
        .clk(clk_100MHz), 
        .start(start_6), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_2), 
        .biases_flat(bias_layer1_2), 
        .out_vector_flat(output_layer1_2), 
        .done(start_7)
    );
    
    weight_loader_layer2 w3(
        .clk(clk_100MHz), 
        .start(start_8), 
        .data_out(weight_layer2), 
        .done(start_9)
    );
    
    bias_loader_layer2 b3(
        .clk(clk_100MHz), 
        .start(start_9),
        .data_out(bias_layer2), 
        .done(start_10)
    );
    
    fc_layer2_flattened m3(
        .clk(clk_100MHz),
        .start(start_10), 
        .in_vector_flat(output_layer1), 
        .weights_flat(weight_layer2), 
        .biases_flat(bias_layer2), 
        .out_vector_flat(output_layer2),
        .done(start_11)
    );
    
    // Main FSM
    always @(posedge clk_uart) begin
        case(state)
            INPUT: begin
                if(~flush_ctrl && ~converted)
                    allow_next <= 1;     // Allow next RX cycle
                
                if(converted && ~flush_ctrl && allow_next) begin
                    // Store received byte in flat buffer
                    input_buffer[input_counter*8 +:8] <= uart_data;
                    input_counter <= input_counter + 1;
                    flush_ctrl <= 1;     // Flush RX buffer
                    allow_next <= 0;
                    // Check if all bytes received
                    if(input_counter == 63) begin
                        start_1 <= 1'b1;
                        state <= OUTPUT_LAYER_1;
                        input_counter <= 0;
                    end
                end
                else begin
                flush_ctrl <= 0;    // Clear flush after 1 cycle
                end
            end
            
            OUTPUT_LAYER_1: begin
                if (start_7) begin
                    start_8 <= 1'b1;
                    state <= OUTPUT_LAYER_2; 
                    output_layer1 <= {output_layer1_2,output_layer1_1};
                end
            end
            
            OUTPUT_LAYER_2: begin
                if (start_11) begin
                    state <= FINAL_OUTPUT; 
                    output_buffer <= output_layer2;
                end
            end
            
            FINAL_OUTPUT: begin
                if (!tx_busy) begin
                    if (output_counter < 10) begin
                        tx_enable <= 1;
                        tx_data <= output_buffer[output_counter*8 +:8];
                        output_counter <= output_counter + 1;
                    end else begin
                        tx_enable <= 0;
                        state <= INPUT;
                        input_counter <= 0;
                    end
                end
            end
        endcase
    end   
    
endmodule
