`timescale 1ns/1ps

module apb_sram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_DEPTH  = 10,     // 2^10 = 1024 words
    parameter int MAX_WAIT   = 8       // Maximum wait states
) (
    // APB Interface
    input  logic                     pclk,
    input  logic                     presetn,   // active low reset
    
    input  logic                     psel,
    input  logic                     penable,
    input  logic                     pwrite,
    input  logic [ADDR_WIDTH-1:0]    paddr,
    input  logic [DATA_WIDTH-1:0]    pwdata,
    
    output logic [DATA_WIDTH-1:0]    prdata,
    output logic                     pready,
    output logic                     pslverr
);

    // =============================================
    // Local parameters & signals
    // =============================================
    localparam int MEM_SIZE = 1 << MEM_DEPTH;

    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        SETUP       = 2'b01,
        ACCESS_WAIT = 2'b10
    } apb_state_e;

    logic [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];
    logic [ADDR_WIDTH-1:0] latched_addr;
    logic [DATA_WIDTH-1:0] latched_wdata;
    logic                  latched_pwrite;
    logic [7:0]            wait_cycles;
    logic [7:0]            wait_cnt;
    apb_state_e            state;

    // =============================================
    // Main APB FSM
    // =============================================
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            state         <= IDLE;
            wait_cycles   <= '0;
            wait_cnt      <= '0;
            pready        <= 1'b1;        // recommended default in idle
            pslverr       <= 1'b0;
            prdata        <= '0;
            latched_addr  <= '0;
            latched_wdata <= '0;
            latched_pwrite<= 1'b0;

            foreach (mem[i]) mem[i] <= '0;
        end else begin
            // Default outputs when not actively waiting
            pready  <= 1'b1;
            pslverr <= 1'b0;

            case (state)
                IDLE: begin
                    if (psel && !penable) begin
                        // Start setup phase
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        wait_cnt       <= '0;
                        state          <= SETUP;
                    end
                end

                SETUP: begin
                    if (!psel) begin
                        state <= IDLE;
                    end else if (psel && penable) begin
                        if (wait_cycles == 0) begin
                            // Immediate response in the first ACCESS cycle
                            pready <= 1'b1;

                            if (latched_addr >= MEM_SIZE) begin
                                pslverr <= 1'b1;
                                prdata  <= 32'hDEADBEEF;
                            end else if (latched_pwrite) begin
                                mem[latched_addr[MEM_DEPTH-1:0]] <= latched_wdata;
                            end else begin
                                prdata <= mem[latched_addr[MEM_DEPTH-1:0]];
                            end

                            state <= IDLE;
                        end else begin
                            // Enter wait-state access phase
                            pready   <= 1'b0;
                            wait_cnt <= 8'd1;
                            state    <= ACCESS_WAIT;
                        end
                    end
                end

                ACCESS_WAIT: begin
                    if (!psel) begin
                        state <= IDLE;
                    end else if (!penable) begin
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        wait_cnt       <= '0;
                        state          <= SETUP;
                    end else begin
                        pready <= 1'b0;
                        if (wait_cnt < wait_cycles) begin
                            wait_cnt <= wait_cnt + 1;
                        end else begin
                            pready <= 1'b1;

                            if (latched_addr >= MEM_SIZE) begin
                                pslverr <= 1'b1;
                                prdata  <= 32'hDEADBEEF;
                            end else if (latched_pwrite) begin
                                mem[latched_addr[MEM_DEPTH-1:0]] <= latched_wdata;
                            end else begin
                                prdata <= mem[latched_addr[MEM_DEPTH-1:0]];
                            end

                            state <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
