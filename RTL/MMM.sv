module MMM #(
    parameter INW = 12,
    parameter OUTW = 32,
    parameter M = 7,
    parameter N = 9,
    parameter MAXK = 8,
    localparam K_BITS = $clog2(MAXK+1)
)(
    input clk,
    input reset,
    input [INW-1:0] INPUT_TDATA,
    input INPUT_TVALID,
    input [K_BITS:0] INPUT_TUSER,
    output INPUT_TREADY,
    output [OUTW-1:0] OUTPUT_TDATA,
    output OUTPUT_TVALID,
    input OUTPUT_TREADY
);

    // Internal signals
    wire matrices_loaded;
    wire [INW-1:0] A_data, B_data;
    wire [OUTW-1:0] mac_result;
    wire [$clog2(M*MAXK)-1:0] A_read_addr;
    wire [$clog2(MAXK*N)-1:0] B_read_addr;
    wire clear_acc, valid_input, wr_en;
    reg compute_finished;
    wire [K_BITS-1:0] K;
    wire [$clog2(N+1)-1:0] fifo_capacity;

    // FSM states
    typedef enum logic [2:0] {IDLE, LOAD, COMPUTE, WRITE_OUTPUT, STALL} state_t;
    state_t current_state, next_state;

    // Counters
    reg [$clog2(M)-1:0] m_counter;
    reg [$clog2(N)-1:0] n_counter;
    reg [$clog2(MAXK)-1:0] k_counter;

    // Input Memory module instantiation
    input_mems #(
        .INW(INW),
        .M(M),
        .N(N),
        .MAXK(MAXK)
    ) input_memories (
        .clk(clk),
        .reset(reset),
        .INPUT_TDATA(INPUT_TDATA),
        .INPUT_TVALID(INPUT_TVALID),
        .INPUT_TUSER(INPUT_TUSER),
        .INPUT_TREADY(INPUT_TREADY),
        .A_read_addr(A_read_addr),
        .B_read_addr(B_read_addr),
        .A_data(A_data),
        .B_data(B_data),
        .matrices_loaded(matrices_loaded),
        .compute_finished(compute_finished),
        .K(K)
    );

    // MAC module instantiation
    mac_pipe #(
        .INW(INW),
        .OUTW(OUTW)
    ) mac_unit (
        .clk(clk),
        .reset(reset),
        .A(A_data),
        .B(B_data),
        .clear_acc(clear_acc),
        .valid_input(valid_input),
        .C(mac_result)
    );

    // Output FIFO instantiation
    fifo_out #(
        .OUTW(OUTW),
        .DEPTH(N)
    ) out_fifo (
        .clk(clk),
        .reset(reset),
        .data_in(mac_result),
        .wr_en(wr_en),
        .capacity(fifo_capacity),
        .AXIS_TDATA(OUTPUT_TDATA),
        .AXIS_TVALID(OUTPUT_TVALID),
        .AXIS_TREADY(OUTPUT_TREADY)
    );

    // Control logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            m_counter <= 0;
            n_counter <= 0;
            k_counter <= 0;
            compute_finished <= 0;
        end else begin
            current_state <= next_state;
            case (current_state)
                LOAD: begin
                    if (matrices_loaded) begin
                        m_counter <= 0;
                        n_counter <= 0;
                        k_counter <= 0;
                    end
                end
                COMPUTE: begin
                    if (k_counter == K - 1) begin
                        k_counter <= 0;
                        if (n_counter == N - 1) begin
                            n_counter <= 0;
                            if (m_counter == M - 1) begin
                                m_counter <= 0;
                            end else begin
                                m_counter <= m_counter + 1;
                            end
                        end else begin
                            n_counter <= n_counter + 1;
                        end
                    end else begin
                        k_counter <= k_counter + 1;
                    end
                end
                WRITE_OUTPUT: begin
                    compute_finished <= 1;
                end
                default: begin
                    m_counter <= 0;
                    n_counter <= 0;
                    k_counter <= 0;
                    compute_finished <= 0;
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: next_state = LOAD;
            LOAD: if (matrices_loaded) next_state = COMPUTE;
            COMPUTE: begin
                if (m_counter == M - 1 && n_counter == N - 1 && k_counter == K - 1)
                    next_state = WRITE_OUTPUT;
                else if (fifo_capacity == 0)
                    next_state = STALL;
            end
            STALL: if (fifo_capacity > 0) next_state = COMPUTE;
            WRITE_OUTPUT: next_state = LOAD;
        endcase
    end

    // Control signals
    assign A_read_addr = m_counter * K + k_counter;
    assign B_read_addr = k_counter * N + n_counter;
    assign clear_acc = (k_counter == 0);
    assign valid_input = (current_state == COMPUTE);
    assign wr_en = (k_counter == K - 1 && current_state == COMPUTE);

endmodule