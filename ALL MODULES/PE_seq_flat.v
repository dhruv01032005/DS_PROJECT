`timescale 1ns / 1ps

module PE_seq_flat #(
    parameter VECTOR_LENGTH = 16,
    parameter W = 8,
    parameter ACC_WIDTH = W+7
)(
    input clk,
    input reset,
    input start,
    input signed [W*VECTOR_LENGTH-1:0] in_vector_flat,
    input signed [W*VECTOR_LENGTH-1:0] weight_row_flat,
    input signed [W-1:0] bias,
    output reg signed [ACC_WIDTH-1:0] result,
    output reg done
);

    reg [31:0] index;
    reg signed [ACC_WIDTH-1:0] acc;
    reg signed [ACC_WIDTH-1:0] in_val;
    reg signed [ACC_WIDTH-1:0] w_val;

    // sign extension function (to allow negative intermediate outputs)
    function automatic signed [ACC_WIDTH-1:0] sign_extend;
        input signed [W-1:0] value;
        begin
            sign_extend = {{(ACC_WIDTH-W){value[W-1]}}, value};
        end
    endfunction

    always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        acc <= 0;
        result <= 0;
        done <= 0;
    end else if (start) begin
        index <= 0;
        acc <= 0;
        done <= 0;
    end else if (!done) begin
        in_val = sign_extend(in_vector_flat[index*W +: W]);
        w_val = sign_extend(weight_row_flat[index*W +: W]);
        
        if (index == VECTOR_LENGTH-1) begin
            result <= (acc + in_val*w_val) + bias;
            done <= 1;
            acc <= acc+in_val*w_val;
        end else begin
            acc <= acc + in_val * w_val;
            index <= index + 1;
        end
    end
end
endmodule