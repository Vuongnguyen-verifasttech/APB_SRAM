`timescale 1ns/1ps
//==============================================================================
// File        : apb_sram.sv
// Description : APB Slave SRAM với wait state ngẫu nhiên
//               Fix: bỏ default pready<=1 ở đầu always_ff.
//               pready được gán tường minh trong từng state để tránh
//               NBA override làm mất wait state.
// Parameters  :
//   ADDR_WIDTH – độ rộng địa chỉ (default 32)
//   DATA_WIDTH – độ rộng dữ liệu (default 32)
//   MEM_DEPTH  – log2(số words) ví dụ 10 → 1024 words (default 10)
//   MAX_WAIT   – số wait state tối đa mỗi transaction (default 8)
//==============================================================================

module apb_sram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_DEPTH  = 10,
    parameter int MAX_WAIT   = 8
) (
    input  logic                  pclk,
    input  logic                  presetn,   // active-low reset

    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,

    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr
);

    // =========================================================================
    // Local parameters & internal signals
    // =========================================================================
    localparam int MEM_SIZE = 1 << MEM_DEPTH;

    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        SETUP       = 2'b01,
        ACCESS_WAIT = 2'b10
    } apb_state_e;

    logic [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];

    // Latched transaction info (captured during SETUP phase)
    logic [ADDR_WIDTH-1:0] latched_addr;
    logic [DATA_WIDTH-1:0] latched_wdata;
    logic                  latched_pwrite;

    // Wait-state control
    logic [7:0] wait_cycles;   // số wait state được random
    logic [7:0] wait_cnt;      // đếm số cycle đã chờ

    apb_state_e state;

    // =========================================================================
    // Helper task – thực hiện memory operation và cập nhật output
    // (dùng trong cả SETUP→ACCESS_WAIT=0 lẫn ACCESS_WAIT khi done)
    // =========================================================================
    // Không dùng task trong always_ff (tool compatibility), inline thay thế.

    // =========================================================================
    // Main APB FSM
    // =========================================================================
    always_ff @(posedge pclk or negedge presetn) begin

        // ------------------------------------------------------------------
        // RESET
        // ------------------------------------------------------------------
        if (!presetn) begin
            state          <= IDLE;
            wait_cycles    <= '0;
            wait_cnt       <= '0;
            pready         <= 1'b1;   // APB spec: pready=1 khi không có transaction
            pslverr        <= 1'b0;
            prdata         <= '0;
            latched_addr   <= '0;
            latched_wdata  <= '0;
            latched_pwrite <= 1'b0;
            foreach (mem[i]) mem[i] <= '0;

        // ------------------------------------------------------------------
        // NORMAL OPERATION
        // Không có dòng "default pready<=1" ở đây.
        // pready được gán tường minh trong mỗi nhánh để tránh
        // NBA override che mất pready<=0 của wait state.
        // ------------------------------------------------------------------
        end else begin

            case (state)

                // ==============================================================
                // IDLE – bus rảnh, pready=1 (idle convention)
                // ==============================================================
                IDLE: begin
                    pready  <= 1'b1;
                    pslverr <= 1'b0;

                    if (psel && !penable) begin
                        // Master bắt đầu SETUP phase:
                        // latch địa chỉ / data / direction
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        // Random số wait state cho transaction này
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        wait_cnt       <= '0;
                        state          <= SETUP;
                        // pready giữ 1'b1 trong SETUP phase (master chưa assert penable)
                    end
                end

                // ==============================================================
                // SETUP – psel=1, penable=0
                // Slave giữ pready=1 (APB spec: pready không quan trọng khi penable=0)
                // Chờ master assert penable để vào ACCESS phase
                // ==============================================================
                SETUP: begin
                    pready  <= 1'b1;   // spec: slave có thể giữ bất kỳ giá trị,
                    pslverr <= 1'b0;   // nhưng giữ =1 là safe/conventional

                    if (!psel) begin
                        // Master hủy giao dịch
                        state <= IDLE;

                    end else if (psel && penable) begin
                        // Master assert penable → bắt đầu ACCESS phase
                        if (wait_cycles == 0) begin
                            // ── Không có wait state: hoàn thành ngay cycle này ──
                            pready  <= 1'b1;
                            pslverr <= 1'b0;
                            do_mem_op();
                            state <= IDLE;

                        end else begin
                            // ── Cần wait state: kéo pready xuống 0 ──
                            pready   <= 1'b0;   // <-- bắt đầu wait
                            wait_cnt <= 8'd1;
                            state    <= ACCESS_WAIT;
                        end
                    end
                    // else: psel=1 nhưng penable vẫn =0, ở lại SETUP
                end

                // ==============================================================
                // ACCESS_WAIT – psel=1, penable=1, pready=0 (slave đang bận)
                // Slave đếm wait cycle, khi đủ thì set pready=1 và hoàn thành
                // ==============================================================
                ACCESS_WAIT: begin

                    if (!psel) begin
                        // Master abort giữa chừng → về IDLE
                        pready  <= 1'b1;
                        pslverr <= 1'b0;
                        state   <= IDLE;

                    end else if (!penable) begin
                        // penable hạ trong ACCESS phase: không hợp lệ theo APB spec,
                        // nhưng xử lý phòng thủ – coi như SETUP phase mới
                        pready         <= 1'b1;
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        wait_cnt       <= '0;
                        state          <= SETUP;

                    end else begin
                        // penable=1: tiếp tục đếm wait state
                        if (wait_cnt < wait_cycles) begin
                            // ── Vẫn còn wait cycle ──
                            pready   <= 1'b0;   // giữ thấp
                            pslverr  <= 1'b0;
                            wait_cnt <= wait_cnt + 8'd1;

                        end else begin
                            // ── Đã đủ wait cycle: hoàn thành transaction ──
                            pready  <= 1'b1;
                            pslverr <= 1'b0;
                            do_mem_op();
                            state <= IDLE;
                        end
                    end
                end

                // ==============================================================
                // Default: bảo vệ khỏi state không hợp lệ
                // ==============================================================
                default: begin
                    pready  <= 1'b1;
                    pslverr <= 1'b0;
                    state   <= IDLE;
                end

            endcase
        end
    end

    // =========================================================================
    // do_mem_op – thực hiện READ / WRITE vào memory
    // Gọi inline bằng task (được phép trong always_ff với SystemVerilog)
    // =========================================================================
    task automatic do_mem_op();
        if (latched_addr >= ADDR_WIDTH'(MEM_SIZE)) begin
            // Địa chỉ ngoài phạm vi → slave error
            pslverr <= 1'b1;
            prdata  <= DATA_WIDTH'('hDEAD_BEEF);
        end else if (latched_pwrite) begin
            // WRITE
            mem[latched_addr[MEM_DEPTH-1:0]] <= latched_wdata;
        end else begin
            // READ
            prdata  <= mem[latched_addr[MEM_DEPTH-1:0]];
            pslverr <= 1'b0;
        end
    endtask

endmodule