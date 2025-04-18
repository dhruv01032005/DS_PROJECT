`timescale 1ns / 1ps

module controller_2(
    input clk_100MHz,  // System clock
    input rx,           // UART receive input
    output tx,          // UART transmit output
    output rx_busy,     // UART RX busy flag
    output converted,   // UART RX data converted flag
    output data_valid,  // UART RX data valid flag
    output tx_busy      // UART TX busy flag
);
    
    // New FSM states
    localparam STORE_INPUT    = 0; // Receive 1152 bytes
    localparam PREPROCESS     = 1; // Processing stage
    localparam TRANSMIT_OUTPUT = 2; // Transmit 10 bytes
    
    reg [1:0] state; // Reduced to 2 bits for 3 states
    reg [10:0] input_counter; // 1152 needs 11 bits (2048 max)
    reg [3:0] output_counter; // 10 needs 4 bits
    
    // Data storage as flat vectors
    reg [9215:0] input_buffer;  // 1152 bytes = 1152*8 bits
    reg [79:0] output_buffer;   // 10 bytes = 10*8 bits
    
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
        counter = 0;
        clk_uart = 0;
        flush_ctrl = 0;
        tx_enable = 0;
        input_buffer = 9216'b0;
        output_buffer = 80'b0;
        state = STORE_INPUT;
        input_counter = 0;
        output_counter = 0;
        allow_next <=0;
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
            case(state)
                // State 1: Store 1152 bytes
                // Modified STORE_INPUT state with flow control
                STORE_INPUT: begin
                    tx_enable <= 0;          // Keep TX disabled during reception
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
                            state <= PREPROCESS;
                        input_counter <= 0;
                        end
                    end
                    else begin
                    flush_ctrl <= 0;    // Clear flush after 1 cycle
                    end
                end
                
                // State 2: Preprocessing
                PREPROCESS: begin
                    // Example preprocessing: copy first 10 bytes
                    output_buffer <= input_buffer[0 +:80]; // First 10 bytes
                    state <= TRANSMIT_OUTPUT;
                    output_counter <= 0;
                end
                
                // State 3: Transmit 10 bytes
                TRANSMIT_OUTPUT: begin
                    if (!tx_busy) begin
                        if (output_counter < 10) begin
                            tx_data <= output_buffer[output_counter*8 +:8];
                            tx_enable <= 1;
                            output_counter <= output_counter + 1;
                        end else begin
                            tx_enable <= 0;
                            // Return to initial state
                            state <= STORE_INPUT;
                            input_counter <= 0;
                        end
                    end
                end
            endcase
        end
        
endmodule
