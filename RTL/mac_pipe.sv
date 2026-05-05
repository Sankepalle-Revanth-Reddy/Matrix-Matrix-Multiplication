module mac_pipe #(
    parameter INW  = 16,
    parameter OUTW = 48,
    localparam MINVAL = -1*(64'd1<<(OUTW -1)),
    localparam MAXVAL = (64'd1<<(OUTW -1)) -1
)(
    input signed [INW-1:0]  in0, in1,
    output logic signed [OUTW-1:0] out,
    input clk, reset, clear_acc, valid_input
);
    
    logic signed [2*INW :0] mult_op, mult_reg;
    logic signed [OUTW :0] ACC_op; //extra bit in case of overflow. 
    
    assign mult_op = in0 * in1;
    
    always_ff @(posedge clk) begin
        if (valid_input == 1) begin
            mult_reg <= mult_op;
        end
        else begin
            mult_reg <= 1'b0;
        end
    end
    
    always_comb begin
        ACC_op = out + mult_reg;
		if (ACC_op > $signed(MAXVAL)) begin
            ACC_op = MAXVAL;
        end
        else if (ACC_op < $signed(MINVAL)) begin
            ACC_op = MINVAL;
        end
    end
    
    always_ff @(posedge clk) begin
        if (clear_acc == 1 || reset == 1) begin
            out <= 0;
        end
        else begin
            out <= ACC_op;
        end
    end
endmodule
