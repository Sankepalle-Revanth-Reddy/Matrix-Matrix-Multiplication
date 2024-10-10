module mac_pipe #(
    parameter INW = 16,
    parameter OUTW = 48,
    localparam MINVAL = -1*(64'd1<<(OUTW-1)),
    localparam MAXVAL = (64'd1<<(OUTW-1))-1
)(
    input signed [INW-1:0] in0, in1,
    output logic signed [OUTW-1:0] out,
    input clk, reset, clear_acc, valid_input
);

    logic signed [2*INW-1:0] mult_result, mult_reg;
    logic signed [OUTW:0] add_result, saturated_result;
    logic signed [OUTW:0] acc_reg;
    logic valid_delayed;

    // Multiplication
    assign mult_result = in0 * in1;

    // Pipeline register for multiplication result
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            mult_reg <= '0;
        else if (valid_input)
            mult_reg <= mult_result;
    end

    // Addition
    assign add_result = acc_reg + mult_reg;

    // Saturation logic
    always_comb begin
        if (add_result >$signed(MAXVAL)) 
            saturated_result = MAXVAL;
        else if (add_result < $signed(MINVAL))
            saturated_result = MINVAL;
        else
            saturated_result = add_result;
    end

    // Delay valid_input by one cycle
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            valid_delayed <= 1'b0;
        else
            valid_delayed <= valid_input;
    end

    // Accumulator register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            acc_reg <= '0;
        else if (clear_acc)
            acc_reg <= '0;
        else if (valid_delayed)
            acc_reg <= saturated_result;
    end

    // Output assignment
    assign out = acc_reg;

endmodule