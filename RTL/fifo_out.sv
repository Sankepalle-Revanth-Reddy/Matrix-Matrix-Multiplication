module fifo_out #(
    parameter OUTW = 48,
    parameter DEPTH = 17,
    localparam LOGDEPTH = $clog2(DEPTH)
)(
    input clk,
    input reset,
    input [OUTW-1:0] data_in,
    input wr_en,
    output logic [$clog2(DEPTH+1)-1:0] capacity,
    output logic [OUTW-1:0] AXIS_TDATA,
    output logic AXIS_TVALID,
    input AXIS_TREADY
);

logic rd_en;
logic [LOGDEPTH-1:0] tail, head;
logic [LOGDEPTH-1:0] rd_addr;
logic [OUTW-1:0] mem_out;

memory_dual_port #(.WIDTH(OUTW), .SIZE(DEPTH)) fifo_mem (
    .clk(clk),
    .data_in(data_in),
    .data_out(mem_out),
    .write_addr(head),
    .read_addr(rd_addr),
    .wr_en(wr_en)
);

// AXI Stream Interface
always_comb begin
    if (capacity == DEPTH) begin
        AXIS_TVALID = 1'b0;
    end else begin
        AXIS_TVALID = 1'b1;
    end
    
    if (AXIS_TVALID && AXIS_TREADY) begin
        rd_en = 1'b1;
    end else begin
        rd_en = 1'b0;
    end
    
    AXIS_TDATA = mem_out;
end

// Capacity logic 
always_ff @(posedge clk) begin
    if (reset) begin
        capacity <= DEPTH;
    end else if (rd_en && !wr_en) begin
        capacity <= capacity + 1;
    end else if (!rd_en && wr_en) begin
        capacity <= capacity - 1;
    end
end


///head logic.
	/*always_ff@(posedge clk)begin
		if(reset)begin
			wr_addr <=0;
		else if(wr_en == 1)
			if(wr_addr == DEPTH -1)
				wr_addr <=0;
			else 
			wr_addr <= wr_addr + 1;
		else 
		wr_addr <= wr_addr;
		end
	end*/
always_ff @(posedge clk) begin
    if (reset)
        head <= '0;
    else if (wr_en)
        head <= (head == DEPTH-1) ? '0 : head + 1;
end

// Tail logic

/*always_ff @(posedge clk) begin 
		if (reset == 1) begin
			tail <= 0;
		end
		else if (rd_en == 1) begin
			tail <= tail+1; // if its not in the last postion, then increment the head location!
			if (tail == DEPTH-1) begin // go back to the starting postion of the fifo when the last postion has been reached! - wrap around
				tail <= 0;
			end
		end
		else begin
			tail <= tail;
		end
	end	
	always_comb begin
    	if (rd_en == 1) begin
    		rd_addr = tail+1;
    	end	
    	else if (rd_en == 0) begin
    		rd_addr = tail;
    	end	
    	else if (tail == DEPTH-1) begin
       		 rd_addr = 0;
   		end    	
    	
	end*/
always_ff @(posedge clk) begin
    if (reset)
        tail <= '0;
    else if (rd_en)
        tail <= (tail == DEPTH-1) ? '0 : tail + 1;
end

// Read address logic
always_comb begin
    if (rd_en)
        rd_addr = (tail == DEPTH-1) ? '0 : tail + 1;
    else
        rd_addr = tail;
end

endmodule


// ESE 507 Stony Brook University
// Peter Milder
// You may not redistribute this code.
// Dual-port Memory to use for output FIFO

module memory_dual_port #(
        parameter                WIDTH=16, SIZE=64,
        localparam               LOGSIZE=$clog2(SIZE)
    )(
        input [WIDTH-1:0]        data_in,
        output logic [WIDTH-1:0] data_out,
        input [LOGSIZE-1:0]      write_addr, read_addr,
        input                    clk, wr_en
    );
       
    logic [SIZE-1:0][WIDTH-1:0] mem;
    
    always_ff @(posedge clk) begin
        data_out <= mem[read_addr];
        if (wr_en) begin            
            mem[write_addr] <= data_in;
            
            // if we are reading and writing to same address concurrently, 
            // then output the new data
            if (read_addr == write_addr)
                data_out <= data_in;
        end
    end

endmodule
