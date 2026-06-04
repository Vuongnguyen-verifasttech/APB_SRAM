`timescale 1ns/1ps
//==============================================================================
// File        : apb_sram.sv
// Description : APB Slave SRAM với wait state ngẫu nhiên
//
// Fixes so với bản trước:
//   [F1] pready hạ xuống 0 ngay tại SETUP phase (khi psel=1, penable=0) nếu
//        wait_cycles > 0 – đúng theo spec Case 2 (Wait-State Slave).
//        Trước đó pready chỉ hạ ở ACCESS_WAIT nên waveform thấy pready=1
//        suốt SETUP, driver tưởng no-wait và kết thúc sớm.
//
//   [F2] Bộ đếm wait_cnt khởi tạo = 0 (không phải 1) và điều kiện done
//        là wait_cnt == wait_cycles (không phải <). Trước đó khởi tạo
//        wait_cnt=1 làm mất 1 wait cycle, ACCESS_WAIT chỉ sống 1 clk
//        dù wait_cycles=8.
//
//   [F3] Không có dòng default "pready<=1" ở đầu always_ff để tránh
//        NBA override che mất pready<=0 của wait state.
//
// Luồng chuẩn (Wait-State Case):
//   IDLE  : pready=1, psel=0
//   SETUP : psel=1, penable=0
//           → latch addr/data/ctrl, random wait_cycles
//           → nếu wait_cycles>0: pready<=0 ngay tại đây
//           → nếu wait_cycles=0: giữ pready=1
//   ACCESS_WAIT: psel=1, penable=1, pready=0
//           → đếm wait_cnt từ 0 đến wait_cycles-1 (wait_cycles chu kỳ)
//           → khi wait_cnt == wait_cycles-1: thực hiện mem op, pready<=1
//           → chuyển về IDLE
//==============================================================================

module apb_sram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_DEPTH  = 10,   // 2^10 = 1024 words
    parameter int MAX_WAIT   = 8     // wait state tối đa mỗi transaction
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
    // Tham số nội bộ & khai báo tín hiệu
    // =========================================================================
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

    logic [7:0] wait_cycles;   // số wait cycle random cho transaction hiện tại
    logic [7:0] wait_cnt;      // bộ đếm: 0 .. wait_cycles-1

    apb_state_e state;

    // =========================================================================
    // APB FSM
    // =========================================================================
    always_ff @(posedge pclk or negedge presetn) begin

        // ── RESET ─────────────────────────────────────────────────────────────
        if (!presetn) begin
            state          <= IDLE;
            wait_cycles    <= '0;
            wait_cnt       <= '0;
            pready         <= 1'b1;   // spec: slave sẵn sàng khi bus rảnh
            pslverr        <= 1'b0;
            prdata         <= '0;
            latched_addr   <= '0;
            latched_wdata  <= '0;
            latched_pwrite <= 1'b0;
            foreach (mem[i]) mem[i] <= '0;

        // ── HOẠT ĐỘNG BÌNH THƯỜNG ─────────────────────────────────────────────
        // KHÔNG có default pready<=1 ở đây.
        // Mỗi state / nhánh gán pready tường minh.
        end else begin

            case (state)

                // ==============================================================
                // IDLE: bus rảnh
                //   pready = 1 (slave luôn sẵn sàng khi không có transaction)
                //   Chờ master bắt đầu SETUP (psel=1, penable=0)
                // ==============================================================
                IDLE: begin
                    pready  <= 1'b1;
                    pslverr <= 1'b0;

                    if (psel && !penable) begin
                        // Latch thông tin transaction
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        // Random wait cycles cho transaction này
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        wait_cnt       <= '0;
                        state          <= SETUP;
                        // pready sẽ được set đúng ở SETUP state cycle sau
                    end
                end

                // ==============================================================
                // SETUP: psel=1, penable=0
                //   [F1] Nếu wait_cycles > 0 → hạ pready=0 ngay tại đây.
                //        Master sẽ thấy pready=0 khi nó assert penable,
                //        biết slave chưa sẵn sàng và phải giữ penable chờ.
                //   Nếu wait_cycles == 0 → giữ pready=1 (no-wait slave)
                // ==============================================================
                SETUP: begin
                    if (!psel) begin
                        // Master hủy giao dịch → về IDLE
                        pready <= 1'b1;
                        state  <= IDLE;

                    end else begin
                        // [F1] Báo hiệu cho master sớm nhất có thể:
                        if (wait_cycles == 0) begin
                            pready <= 1'b1;   // no-wait: giữ pready=1 xuyên suốt
                        end else begin
                            pready <= 1'b0;   // wait: kéo pready=0 để master chờ
                        end
                        pslverr <= 1'b0;

                        if (psel && penable) begin
                            // Master assert penable → vào ACCESS phase
                            if (wait_cycles == 0) begin
                                // No-wait: hoàn thành ngay cycle này
                                pready <= 1'b1;
                                do_mem_op();
                                state  <= IDLE;
                            end else begin
                                // Wait: chuyển sang ACCESS_WAIT, đếm từ 0
                                // [F2] wait_cnt đã được set = 0 ở IDLE,
                                //      giữ nguyên, bắt đầu đếm ở ACCESS_WAIT
                                state <= ACCESS_WAIT;
                            end
                        end
                        // else: penable vẫn =0, ở lại SETUP, pready đã set ở trên
                    end
                end

                // ==============================================================
                // ACCESS_WAIT: psel=1, penable=1, pready=0
                //   Đếm wait_cnt từ 0 đến wait_cycles-1.
                //   Tổng số cycle trong ACCESS_WAIT = wait_cycles cycle.
                //   [F2] wait_cnt khởi từ 0, done khi wait_cnt == wait_cycles-1
                //        (tức là đã chạy wait_cycles chu kỳ).
                // ==============================================================
                ACCESS_WAIT: begin

                    if (!psel) begin
                        // Abort: master hủy giữa chừng
                        pready <= 1'b1;
                        state  <= IDLE;

                    end else if (!penable) begin
                        // penable hạ trong ACCESS (không hợp lệ theo APB spec)
                        // Xử lý phòng thủ: coi như SETUP mới
                        pready         <= 1'b0;   // wait_cycles đã random ≥ 1
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        wait_cnt       <= '0;
                        state          <= SETUP;

                    end else begin
                        // penable=1: slave đang được truy cập, đếm wait
                        if (wait_cnt < wait_cycles - 1) begin
                            // ── Chưa đủ wait cycle: tiếp tục chờ ──
                            pready   <= 1'b0;
                            pslverr  <= 1'b0;
                            wait_cnt <= wait_cnt + 8'd1;

                        end else begin
                            // ── Đủ wait_cycles chu kỳ: hoàn thành transaction ──
                            // wait_cnt == wait_cycles-1 tại đây
                            pready  <= 1'b1;
                            pslverr <= 1'b0;
                            do_mem_op();
                            state   <= IDLE;
                        end
                    end
                end

                // ==============================================================
                // Default: recovery khỏi state không hợp lệ
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
    // do_mem_op: thực hiện READ hoặc WRITE vào memory
    // =========================================================================
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