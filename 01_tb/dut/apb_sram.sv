`timescale 1ns/1ps
//==============================================================================
// File    : apb_sram.sv
// Fix     : Dùng blocking assignment (=) cho wait_cycles trong always_ff
//           để tránh hoàn toàn NBA read-after-write hazard.
//           $urandom_range dùng trong always_ff với blocking = hợp lệ
//           trong SystemVerilog (IEEE 1800-2012 §18.13.1).
//==============================================================================
module apb_sram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_DEPTH  = 10,
    parameter int MAX_WAIT   = 8
) (
    input  logic                  pclk,
    input  logic                  presetn,
    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr
);

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

    // Dùng blocking (=) cho 2 biến này để đọc lại ngay trong cùng always_ff
    // mà không bị NBA hazard.
    logic [7:0] wait_cycles;
    logic [7:0] wait_cnt;

    apb_state_e state;

    always_ff @(posedge pclk or negedge presetn) begin

        if (!presetn) begin
            state          <= IDLE;
            wait_cycles     = '0;   // blocking
            wait_cnt        = '0;   // blocking
            pready         <= 1'b1;
            pslverr        <= 1'b0;
            prdata         <= '0;
            latched_addr   <= '0;
            latched_wdata  <= '0;
            latched_pwrite <= 1'b0;
            foreach (mem[i]) mem[i] <= '0;

        end else begin

            case (state)

                // ------------------------------------------------------------
                // IDLE
                // ------------------------------------------------------------
                IDLE: begin
                    pready  <= 1'b1;
                    pslverr <= 1'b0;
                    wait_cnt = '0;          // blocking: reset counter

                    if (psel && !penable) begin
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;

                        // Blocking: wait_cycles có giá trị MỚI ngay lập tức
                        // trong cùng cycle này, đọc được ở SETUP cycle sau.
                        wait_cycles = $urandom_range(0, MAX_WAIT);

                        state <= SETUP;
                    end
                end

                // ------------------------------------------------------------
                // SETUP  (psel=1, penable=0)
                // wait_cycles đã có giá trị đúng từ blocking ở IDLE
                // ------------------------------------------------------------
                SETUP: begin
                    pslverr <= 1'b0;

                    if (!psel) begin
                        pready <= 1'b1;
                        state  <= IDLE;

                    end else begin
                        // Báo hiệu sớm cho master
                        pready <= (wait_cycles == 8'd0) ? 1'b1 : 1'b0;

                        if (penable) begin
                            if (wait_cycles == 8'd0) begin
                                // No-wait: xong ngay
                                pready <= 1'b1;
                                do_mem_op();
                                state  <= IDLE;
                            end else begin
                                // Vào ACCESS_WAIT, counter = 0
                                wait_cnt = '0;   // blocking: reset trước khi đếm
                                state   <= ACCESS_WAIT;
                            end
                        end
                    end
                end

                // ------------------------------------------------------------
                // ACCESS_WAIT  (psel=1, penable=1, pready=0)
                // Đếm wait_cnt từ 0 đến wait_cycles-1
                // ------------------------------------------------------------
                ACCESS_WAIT: begin

                    if (!psel) begin
                        pready <= 1'b1;
                        state  <= IDLE;

                    end else if (!penable) begin
                        // Illegal per spec – phòng thủ
                        pready         <= 1'b1;
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles     = $urandom_range(0, MAX_WAIT);
                        wait_cnt        = '0;
                        state          <= SETUP;

                    end else begin
                        if (wait_cnt < wait_cycles - 8'd1) begin
                            // Chưa đủ wait cycle
                            pready   <= 1'b0;
                            pslverr  <= 1'b0;
                            wait_cnt  = wait_cnt + 8'd1;  // blocking: tăng ngay
                        end else begin
                            // Đủ rồi
                            pready  <= 1'b1;
                            pslverr <= 1'b0;
                            do_mem_op();
                            state   <= IDLE;
                        end
                    end
                end

                default: begin
                    pready  <= 1'b1;
                    pslverr <= 1'b0;
                    state   <= IDLE;
                end

            endcase
        end
    end

    task automatic do_mem_op();
        if (latched_addr >= ADDR_WIDTH'(MEM_SIZE)) begin
            pslverr <= 1'b1;
            prdata  <= DATA_WIDTH'('hDEAD_BEEF);
        end else if (latched_pwrite) begin
            mem[latched_addr[MEM_DEPTH-1:0]] <= latched_wdata;
        end else begin
            prdata  <= mem[latched_addr[MEM_DEPTH-1:0]];
            pslverr <= 1'b0;
        end
    endtask

endmodule