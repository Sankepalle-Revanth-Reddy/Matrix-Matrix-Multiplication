module mac #(
    parameter INW  = 16,
    parameter OUTW = 48,
    localparam MINVAL = -1*(64'd1<<(OUTW -1)),
    localparam MAXVAL = (64'd1<<(OUTW -1)) -1
	)(
	
    input signed [INW-1:0]  in0, in1,
    output logic signed [OUTW-1:0] out,
	input clk, reset, clear_acc, valid_input);
	    
	logic signed [2*INW :0] OP_MUL ;
	logic signed [OUTW :0] OP_ACC;//extra bit in case of overflow. 
	
	
	
	// stage 1 MAC
	always_comb begin
		OP_MUL = in0*in1;
		OP_ACC = OP_MUL + out;
		if (OP_ACC > $signed(MAXVAL))begin
			OP_ACC = MAXVAL;
		end
		else if (OP_ACC < $signed(MINVAL)) begin
			OP_ACC = MINVAL;
		end
		else begin
			OP_ACC = OP_ACC;
		end
		
	end
	
	
	//stage 2 register values.
	always_ff@(posedge clk) begin
	if(reset == 1) begin
	out<=0;
    end
	else if(clear_acc == 1) begin
	out<=0;
	end
	else if (valid_input == 1) begin
	out<=OP_ACC;
	end
	else begin
	out<=out;
	end
	end
endmodule




	
	
	
	