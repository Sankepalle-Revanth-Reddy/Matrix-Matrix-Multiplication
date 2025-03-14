module input_mems #(
    parameter INW = 24,
    parameter M = 5,
    parameter N = 4,
    parameter MAXK = 6,
    localparam K_BITS = $clog2(MAXK+1),
    localparam A_ADDR_BITS = $clog2(M*MAXK),
    localparam B_ADDR_BITS = $clog2(MAXK*N) 
)(
    input clk, reset,
    input [INW-1:0] AXIS_TDATA,
    input AXIS_TVALID,
    input [K_BITS:0] AXIS_TUSER, 
    output logic AXIS_TREADY, 
    output logic matrices_loaded, 
    input compute_finished, 
    output logic [K_BITS-1:0] K, 
    input [A_ADDR_BITS-1:0] A_read_addr,
    output logic signed [INW-1:0] A_data,
    input [B_ADDR_BITS-1:0] B_read_addr,
    output logic signed [INW-1:0] B_data 
);

    // State definition using Gray code
    typedef enum logic [1:0] {
        IDLE           = 2'b00,
        LOAD_A         = 2'b01,
        LOAD_B         = 2'b11,
        MATRICES_LOADED = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Internal signals
    logic [A_ADDR_BITS-1:0] a_addr;
    logic [B_ADDR_BITS-1:0] b_addr;
    logic a_wr_en, b_wr_en;
    logic [K_BITS-1:0] k_reg;
    logic new_A;
    logic [$clog2(M*MAXK)-1:0] a_counter;
    logic [$clog2(N*MAXK)-1:0] b_counter;

    // Assign new_A and TUSER_K
    assign new_A = AXIS_TUSER[0];
    logic [K_BITS-1:0] TUSER_K;
    assign TUSER_K = AXIS_TUSER[K_BITS:1];

    // Memory instantiation
    memory #(.WIDTH(INW), .SIZE(M*MAXK)) a_mem (
        .clk(clk),
        .data_in(AXIS_TDATA),
        .data_out(A_data),
        .addr(a_addr),
        .wr_en(a_wr_en)
    );

    memory #(.WIDTH(INW), .SIZE(N*MAXK)) b_mem (
        .clk(clk),
        .data_in(AXIS_TDATA),
        .data_out(B_data),
        .addr(b_addr),
        .wr_en(b_wr_en)
    );

    // State machine and control logic
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            k_reg <= '0;
            a_counter <= '0;
            b_counter <= '0;
        end else begin
            current_state <= next_state;
            
            if (AXIS_TVALID && AXIS_TREADY) begin //first checking for valid data and either the module is ready//
                if (current_state == LOAD_A) begin // check for state//
                    if (a_counter == 0)// checking if it is the first element of matrix a, then we push the TUSER_K value into k_reg &intials the counter//
                        k_reg <= TUSER_K;
                    a_counter <= a_counter + 1;
                end else if (current_state == LOAD_B) begin//if in LOAD_B state then intialize the counter_b//
                    b_counter <= b_counter + 1;
                end
            end

            if (compute_finished && current_state == MATRICES_LOADED) begin // when compute finished set all the counter to 0....ready for new values//
                a_counter <= '0;
                b_counter <= '0;
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: if (AXIS_TVALID) next_state = new_A ? LOAD_A : LOAD_B;
            LOAD_A: if (a_counter == M * k_reg - 1 && AXIS_TVALID && AXIS_TREADY) next_state = LOAD_B;
            LOAD_B: if (b_counter == N * k_reg - 1 && AXIS_TVALID && AXIS_TREADY) next_state = MATRICES_LOADED;
            MATRICES_LOADED: if (compute_finished) next_state = IDLE;
        endcase
    end
/*
    // Output logic
    always_comb begin
        AXIS_TREADY = (current_state == LOAD_A || current_state == LOAD_B);
        matrices_loaded = (current_state == MATRICES_LOADED);
        K = k_reg;

        a_wr_en = (current_state == LOAD_A && AXIS_TVALID && AXIS_TREADY);
        b_wr_en = (current_state == LOAD_B && AXIS_TVALID && AXIS_TREADY);

        if (current_state == MATRICES_LOADED) begin
            a_addr = A_read_addr;
            b_addr = B_read_addr;
        end else begin
            a_addr = a_counter;
            b_addr = b_counter;
        end
    end
	*/
// Output logic using assign statements

// AXIS_TREADY logic
assign AXIS_TREADY = (current_state == LOAD_A || current_state == LOAD_B);

// matrices_loaded logic
assign matrices_loaded = (current_state == MATRICES_LOADED);

// K output
assign K = k_reg;

// Write enable signals
assign a_wr_en = (current_state == LOAD_A && AXIS_TVALID && AXIS_TREADY);
assign b_wr_en = (current_state == LOAD_B && AXIS_TVALID && AXIS_TREADY);

// Address selection logic
assign a_addr = (current_state == MATRICES_LOADED) ? A_read_addr : a_counter;
assign b_addr = (current_state == MATRICES_LOADED) ? B_read_addr : b_counter;

endmodule





/*

// ESE 507 Stony Brook University
// Peter Milder
// You may not redistribute this code.
// Memory to use for input_memory module

module memory #(   
        parameter                   WIDTH=16, SIZE=64,
        localparam                  LOGSIZE=$clog2(SIZE)
    )(
        input [WIDTH-1:0]           data_in,
        output logic [WIDTH-1:0]    data_out,
        input [LOGSIZE-1:0]         addr,
        input                       clk, wr_en
    );

    logic [SIZE-1:0][WIDTH-1:0] mem;
    
    always_ff @(posedge clk) begin
        data_out <= mem[addr];
        if (wr_en)
            mem[addr] <= data_in;
    end
endmodule
*/module input_mems #(
    parameter INW = 24,
    parameter M = 5,
    parameter N = 4,
    parameter MAXK = 6,
    localparam K_BITS = $clog2(MAXK+1),
    localparam A_ADDR_BITS = $clog2(M*MAXK),
    localparam B_ADDR_BITS = $clog2(MAXK*N) 
)(
    input clk, reset,
    input [INW-1:0] AXIS_TDATA,
    input AXIS_TVALID,
    input [K_BITS:0] AXIS_TUSER, 
    output logic AXIS_TREADY, 
    output logic matrices_loaded, 
    input compute_finished, 
    output logic [K_BITS-1:0] K, 
    input [A_ADDR_BITS-1:0] A_read_addr,
    output logic signed [INW-1:0] A_data,
    input [B_ADDR_BITS-1:0] B_read_addr,
    output logic signed [INW-1:0] B_data 
);

    // State definition using Gray code
    typedef enum logic [1:0] {
        IDLE           = 2'b00,
        LOAD_A         = 2'b01,
        LOAD_B         = 2'b11,
        MATRICES_LOADED = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Internal signals
    logic [A_ADDR_BITS-1:0] a_addr;
    logic [B_ADDR_BITS-1:0] b_addr;
    logic a_wr_en, b_wr_en;
    logic [K_BITS-1:0] k_reg;
    logic new_A;
    logic [$clog2(M*MAXK)-1:0] a_counter;
    logic [$clog2(N*MAXK)-1:0] b_counter;

    // Assign new_A and TUSER_K
    assign new_A = AXIS_TUSER[0];
    logic [K_BITS-1:0] TUSER_K;
    assign TUSER_K = AXIS_TUSER[K_BITS:1];

    // Memory instantiation
    memory #(.WIDTH(INW), .SIZE(M*MAXK)) a_mem (
        .clk(clk),
        .data_in(AXIS_TDATA),
        .data_out(A_data),
        .addr(a_addr),
        .wr_en(a_wr_en)
    );

    memory #(.WIDTH(INW), .SIZE(N*MAXK)) b_mem (
        .clk(clk),
        .data_in(AXIS_TDATA),
        .data_out(B_data),
        .addr(b_addr),
        .wr_en(b_wr_en)
    );

    // State machine and control logic
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            k_reg <= '0;
            a_counter <= '0;
            b_counter <= '0;
        end else begin
            current_state <= next_state;
            
            if (AXIS_TVALID && AXIS_TREADY) begin //first checking for valid data and either the module is ready//
                if (current_state == LOAD_A) begin // check for state//
                    if (a_counter == 0)// checking if it is the first element of matrix a, then we push the TUSER_K value into k_reg &intials the counter//
                        k_reg <= TUSER_K;
                    a_counter <= a_counter + 1;
                end else if (current_state == LOAD_B) begin//if in LOAD_B state then intialize the counter_b//
                    b_counter <= b_counter + 1;
                end
            end

            if (compute_finished && current_state == MATRICES_LOADED) begin // when compute finished set all the counter to 0....ready for new values//
                a_counter <= '0;
                b_counter <= '0;
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: if (AXIS_TVALID) next_state = new_A ? LOAD_A : LOAD_B;
            LOAD_A: if (a_counter == M * k_reg - 1 && AXIS_TVALID && AXIS_TREADY) next_state = LOAD_B;
            LOAD_B: if (b_counter == N * k_reg - 1 && AXIS_TVALID && AXIS_TREADY) next_state = MATRICES_LOADED;
            MATRICES_LOADED: if (compute_finished) next_state = IDLE;
        endcase
    end
/*
    // Output logic
    always_comb begin
        AXIS_TREADY = (current_state == LOAD_A || current_state == LOAD_B);
        matrices_loaded = (current_state == MATRICES_LOADED);
        K = k_reg;

        a_wr_en = (current_state == LOAD_A && AXIS_TVALID && AXIS_TREADY);
        b_wr_en = (current_state == LOAD_B && AXIS_TVALID && AXIS_TREADY);

        if (current_state == MATRICES_LOADED) begin
            a_addr = A_read_addr;
            b_addr = B_read_addr;
        end else begin
            a_addr = a_counter;
            b_addr = b_counter;
        end
    end
	*/
// Output logic using assign statements

// AXIS_TREADY logic
assign AXIS_TREADY = (current_state == LOAD_A || current_state == LOAD_B);

// matrices_loaded logic
assign matrices_loaded = (current_state == MATRICES_LOADED);

// K output
assign K = k_reg;

// Write enable signals
assign a_wr_en = (current_state == LOAD_A && AXIS_TVALID && AXIS_TREADY);
assign b_wr_en = (current_state == LOAD_B && AXIS_TVALID && AXIS_TREADY);

// Address selection logic
assign a_addr = (current_state == MATRICES_LOADED) ? A_read_addr : a_counter;
assign b_addr = (current_state == MATRICES_LOADED) ? B_read_addr : b_counter;

endmodule





/*

// ESE 507 Stony Brook University
// Peter Milder
// You may not redistribute this code.
// Memory to use for input_memory module

module memory #(   
        parameter                   WIDTH=16, SIZE=64,
        localparam                  LOGSIZE=$clog2(SIZE)
    )(
        input [WIDTH-1:0]           data_in,
        output logic [WIDTH-1:0]    data_out,
        input [LOGSIZE-1:0]         addr,
        input                       clk, wr_en
    );

    logic [SIZE-1:0][WIDTH-1:0] mem;
    
    always_ff @(posedge clk) begin
        data_out <= mem[addr];
        if (wr_en)
            mem[addr] <= data_in;
    end
endmodule
*/module input_mems #(
    parameter INW = 24,
    parameter M = 5,
    parameter N = 4,
    parameter MAXK = 6,
    localparam K_BITS = $clog2(MAXK+1),
    localparam A_ADDR_BITS = $clog2(M*MAXK),
    localparam B_ADDR_BITS = $clog2(MAXK*N) 
)(
    input clk, reset,
    input [INW-1:0] AXIS_TDATA,
    input AXIS_TVALID,
    input [K_BITS:0] AXIS_TUSER, 
    output logic AXIS_TREADY, 
    output logic matrices_loaded, 
    input compute_finished, 
    output logic [K_BITS-1:0] K, 
    input [A_ADDR_BITS-1:0] A_read_addr,
    output logic signed [INW-1:0] A_data,
    input [B_ADDR_BITS-1:0] B_read_addr,
    output logic signed [INW-1:0] B_data 
);

    // State definition using Gray code
    typedef enum logic [1:0] {
        IDLE           = 2'b00,
        LOAD_A         = 2'b01,
        LOAD_B         = 2'b11,
        MATRICES_LOADED = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Internal signals
    logic [A_ADDR_BITS-1:0] a_addr;
    logic [B_ADDR_BITS-1:0] b_addr;
    logic a_wr_en, b_wr_en;
    logic [K_BITS-1:0] k_reg;
    logic new_A;
    logic [$clog2(M*MAXK)-1:0] a_counter;
    logic [$clog2(N*MAXK)-1:0] b_counter;

    // Assign new_A and TUSER_K
    assign new_A = AXIS_TUSER[0];
    logic [K_BITS-1:0] TUSER_K;
    assign TUSER_K = AXIS_TUSER[K_BITS:1];

    // Memory instantiation
    memory #(.WIDTH(INW), .SIZE(M*MAXK)) a_mem (
        .clk(clk),
        .data_in(AXIS_TDATA),
        .data_out(A_data),
        .addr(a_addr),
        .wr_en(a_wr_en)
    );

    memory #(.WIDTH(INW), .SIZE(N*MAXK)) b_mem (
        .clk(clk),
        .data_in(AXIS_TDATA),
        .data_out(B_data),
        .addr(b_addr),
        .wr_en(b_wr_en)
    );

    // State machine and control logic
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            k_reg <= '0;
            a_counter <= '0;
            b_counter <= '0;
        end else begin
            current_state <= next_state;
            
            if (AXIS_TVALID && AXIS_TREADY) begin //first checking for valid data and either the module is ready//
                if (current_state == LOAD_A) begin // check for state//
                    if (a_counter == 0)// checking if it is the first element of matrix a, then we push the TUSER_K value into k_reg &intials the counter//
                        k_reg <= TUSER_K;
                    a_counter <= a_counter + 1;
                end else if (current_state == LOAD_B) begin//if in LOAD_B state then intialize the counter_b//
                    b_counter <= b_counter + 1;
                end
            end

            if (compute_finished && current_state == MATRICES_LOADED) begin // when compute finished set all the counter to 0....ready for new values//
                a_counter <= '0;
                b_counter <= '0;
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: if (AXIS_TVALID) next_state = new_A ? LOAD_A : LOAD_B;
            LOAD_A: if (a_counter == M * k_reg - 1 && AXIS_TVALID && AXIS_TREADY) next_state = LOAD_B;
            LOAD_B: if (b_counter == N * k_reg - 1 && AXIS_TVALID && AXIS_TREADY) next_state = MATRICES_LOADED;
            MATRICES_LOADED: if (compute_finished) next_state = IDLE;
        endcase
    end
/*
    // Output logic
    always_comb begin
        AXIS_TREADY = (current_state == LOAD_A || current_state == LOAD_B);
        matrices_loaded = (current_state == MATRICES_LOADED);
        K = k_reg;

        a_wr_en = (current_state == LOAD_A && AXIS_TVALID && AXIS_TREADY);
        b_wr_en = (current_state == LOAD_B && AXIS_TVALID && AXIS_TREADY);

        if (current_state == MATRICES_LOADED) begin
            a_addr = A_read_addr;
            b_addr = B_read_addr;
        end else begin
            a_addr = a_counter;
            b_addr = b_counter;
        end
    end
	*/
// Output logic using assign statements

// AXIS_TREADY logic
assign AXIS_TREADY = (current_state == LOAD_A || current_state == LOAD_B);

// matrices_loaded logic
assign matrices_loaded = (current_state == MATRICES_LOADED);

// K output
assign K = k_reg;

// Write enable signals
assign a_wr_en = (current_state == LOAD_A && AXIS_TVALID && AXIS_TREADY);
assign b_wr_en = (current_state == LOAD_B && AXIS_TVALID && AXIS_TREADY);

// Address selection logic
assign a_addr = (current_state == MATRICES_LOADED) ? A_read_addr : a_counter;
assign b_addr = (current_state == MATRICES_LOADED) ? B_read_addr : b_counter;

endmodule





/*

// ESE 507 Stony Brook University
// Peter Milder
// You may not redistribute this code.
// Memory to use for input_memory module

module memory #(   
        parameter                   WIDTH=16, SIZE=64,
        localparam                  LOGSIZE=$clog2(SIZE)
    )(
        input [WIDTH-1:0]           data_in,
        output logic [WIDTH-1:0]    data_out,
        input [LOGSIZE-1:0]         addr,
        input                       clk, wr_en
    );

    logic [SIZE-1:0][WIDTH-1:0] mem;
    
    always_ff @(posedge clk) begin
        data_out <= mem[addr];
        if (wr_en)
            mem[addr] <= data_in;
    end
endmodule
*/