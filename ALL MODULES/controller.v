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
    
    // General counters
    reg [8:0] input_counter; // 256 needs 9 bits
    reg [3:0] output_counter; // 10 needs 4 bits
    
    // Data storage as flat vectors
    reg [2047:0] input_buffer;  // 256 bytes = 256*8 bits
    reg [79:0] output_buffer;   // 10 bytes = 10*8 bits
    wire [16383:0] weight_layer1_1; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_1; // 1*8 bytes = 1*8*8 bits
    wire [16383:0] weight_layer1_2; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_2; // 1*8 bytes = 1*8*8 bits
    wire [16383:0] weight_layer1_3; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_3; // 1*8 bytes = 1*8*8 bits
    wire [16383:0] weight_layer1_4; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_4; // 1*8 bytes = 1*8*8 bits
    wire [16383:0] weight_layer1_5; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_5; // 1*8 bytes = 1*8*8 bits
    wire [16383:0] weight_layer1_6; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_6; // 1*8 bytes = 1*8*8 bits
    wire [16383:0] weight_layer1_7; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_7; // 1*8 bytes = 1*8*8 bits
    wire [16383:0] weight_layer1_8; // 256*8 bytes = 256*8*8 bits
    wire [63:0] bias_layer1_8; // 1*8 bytes = 1*8*8 bits
    wire [5119:0] weight_layer2; // 64*10 bytes = 64*10*8 bits
    wire [79:0] bias_layer2; // 1*10 bytes = 1*10*8 bits
    wire done;
    wire start = 1'b1;
    
    // Data storage of outputs after applying the FCL layer
    wire [63:0] output_layer1_1;
    wire [63:0] output_layer1_2;
    wire [63:0] output_layer1_3;
    wire [63:0] output_layer1_4;
    wire [63:0] output_layer1_5;
    wire [63:0] output_layer1_6;
    wire [63:0] output_layer1_7;
    wire [63:0] output_layer1_8;
    reg [511:0] output_layer1;
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
        input_buffer <= 2048'b0;
        output_buffer <= 80'b0;
        input_counter <= 0;
        output_counter <= 0;
        allow_next <= 0;
    end

    // Clock divider for UART (115200 baud)
    always @(posedge clk_100MHz) begin
        counter <= counter + 1;
        if(counter == 5'd27) begin
            counter <= 0;
            clk_uart <= ~clk_uart;
        end
    end

    // Main FSM
    always @(posedge clk_uart) begin
        if(~flush_ctrl && ~converted)
            allow_next <= 1;     // Allow next RX cycle
        
        if(converted && ~flush_ctrl && allow_next) begin
            // Store received byte in flat buffer
            input_buffer[input_counter*8 +:8] <= uart_data;
            input_counter <= input_counter + 1;
            flush_ctrl <= 1;     // Flush RX buffer
            allow_next <= 0;
            
            // Check if all bytes received
            if(input_counter == 1151) begin
            input_counter <= 0;
            end
        end
        else begin
        flush_ctrl <= 0;    // Clear flush after 1 cycle
        end
    end   
    
    weight_loader_layer1_1 w1(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_1), 
        .done(done)
    );
    
    bias_loader_layer1_1 b1(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_1), 
        .done(done)
    );
    
    fc_layer1_flattened m1(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_1), 
        .biases_flat(bias_layer1_1), 
        .out_vector_flat(output_layer1_1), 
        .done(done)
    );
    
    weight_loader_layer1_2 w2(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_2), 
        .done(done)
    );
    
    bias_loader_layer1_2 b2(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_2), 
        .done(done)
    );
    
    fc_layer1_flattened m2(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_2), 
        .biases_flat(bias_layer1_2), 
        .out_vector_flat(output_layer1_2), 
        .done(done)
    );
    
    weight_loader_layer1_3 w3(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_3), 
        .done(done)
    );
    
    bias_loader_layer1_3 b3(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_3), 
        .done(done)
    );
    
    fc_layer1_flattened m3(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_3), 
        .biases_flat(bias_layer1_3), 
        .out_vector_flat(output_layer1_3), 
        .done(done)
    );
    
    weight_loader_layer1_4 w4(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_4), 
        .done(done)
    );
    
    bias_loader_layer1_4 b4(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_4), 
        .done(done)
    );
    
    fc_layer1_flattened m4(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_4), 
        .biases_flat(bias_layer1_4), 
        .out_vector_flat(output_layer1_4), 
        .done(done)
    );
    
    weight_loader_layer1_5 w5(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_5), 
        .done(done)
    );
    
    bias_loader_layer1_5 b5(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_5), 
        .done(done)
    );
    
    fc_layer1_flattened m5(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_5), 
        .biases_flat(bias_layer1_5), 
        .out_vector_flat(output_layer1_5), 
        .done(done)
    );
    
    weight_loader_layer1_6 w6(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_6), 
        .done(done)
    );
    
    bias_loader_layer1_6 b6(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_6), 
        .done(done)
    );
    
    fc_layer1_flattened m6(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_6), 
        .biases_flat(bias_layer1_6), 
        .out_vector_flat(output_layer1_6), 
        .done(done)
    );
    
    weight_loader_layer1_7 w7(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_7), 
        .done(done)
    );
    
    bias_loader_layer1_7 b7(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_7), 
        .done(done)
    );
    
    fc_layer1_flattened m7(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_7), 
        .biases_flat(bias_layer1_7), 
        .out_vector_flat(output_layer1_7), 
        .done(done)
    );
    
    weight_loader_layer1_8 w8(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer1_8), 
        .done(done)
    );
    
    bias_loader_layer1_8 b8(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer1_8), 
        .done(done)
    );
    
    fc_layer1_flattened m8(
        .clk(clk_100MHz), 
        .start(start), 
        .in_vector_flat(input_buffer), 
        .weights_flat(weight_layer1_8), 
        .biases_flat(bias_layer1_8), 
        .out_vector_flat(output_layer1_8), 
        .done(done)
    );
    
    
    always @(posedge clk_uart) begin
        output_layer1 <= {output_layer1_8,output_layer1_7,output_layer1_6,output_layer1_5,output_layer1_4,output_layer1_3,output_layer1_2,output_layer1_1};
    end
    
    weight_loader_layer2 w9(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(weight_layer2), 
        .done(done)
    );
    
    bias_loader_layer2 b9(
        .clk(clk_100MHz), 
        .start(start), 
        .data_out(bias_layer2), 
        .done(done)
    );
    
    fc_layer2_flattened m9(
        .clk(clk_100MHz),
        .start(start), 
        .in_vector_flat(output_layer1), 
        .weights_flat(weight_layer2), 
        .biases_flat(bias_layer2), 
        .out_vector_flat(output_layer2), 
        .done(done)
    );
    
    always @(posedge clk_uart) begin
        output_buffer <= output_layer2;
    end
    
    always @(posedge clk_uart) begin
        tx_enable <= 0;
        if (!tx_busy) begin
            if (output_counter < 10) begin
                    tx_data <= output_buffer[output_counter*8 +:8];
                    tx_enable <= 1;
                    output_counter <= output_counter + 1;
            end else begin
                tx_enable <= 0;
                input_counter <= 0;
            end
        end
    end
    
endmodule