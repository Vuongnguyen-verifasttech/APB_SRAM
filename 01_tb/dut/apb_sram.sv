`timescale 1ns/1ps
//==============================================================================
// File        : apb_sram.sv
// Description : APB Slave SRAM – wait state ngẫu nhiên
//
// Root-cause (bản này fix dứt điểm):
//   wait_cycles được gán NBA (<=) trong IDLE. Khi SETUP→ACCESS_WAIT xảy ra
//   back-to-back (psel và penable cùng lên), wait_cycles đọc trong
//   ACCESS_WAIT vẫn là giá trị CŨ (chưa propagate qua NBA).
//   Kết quả: wait_cnt=0 < wait_cycles_old-1 = FALSE → done ngay 1 cycle.
//
//   Fix dứt điểm:
//   1. wait_cycles được capture vào WIRE COMBINATIONAL (wait_cycles_d)
//      ngay khi IDLE detect transaction → không phụ thuộc NBA timing.
//   2. wait_cycles_d được latch vào reg tại posedge IDLE, đọc trong SETUP
//      và ACCESS_WAIT đều thấy giá trị đúng.
//   3. Bộ đếm: wait_cnt chạy từ 0 đến wait_cycles-1 (inclusive).
//      Done condition: wait_cnt == wait_cycles - 1.
//      Nếu wait_cycles == 0: không vào ACCESS_WAIT, done ngay ở SETUP.
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

    // wait_cycles: register, được latch 1 lần tại posedge IDLE
    // wait_cnt:    bộ đếm tăng mỗi cycle trong ACCESS_WAIT
    logic [7:0] wait_cycles;
    logic [7:0] wait_cnt;

    apb_state_e state;

    // =========================================================================
    // Combinational: sinh wait_cycles MỚI mỗi lần IDLE chuẩn bị transaction.
    // Đây là wire thuần túy – settle ngay trong cùng delta, không phụ thuộc
    // NBA. Giá trị này được latch vào wait_cycles register tại posedge IDLE.
    // =========================================================================
    logic [7:0] wait_cycles_nxt;
    assign wait_cycles_nxt = $urandom_range(0, MAX_WAIT);

    // =========================================================================
    // FSM
    // =========================================================================
    always_ff @(posedge pclk or negedge presetn) begin

        if (!presetn) begin
            state          <= IDLE;
            wait_cycles    <= '0;
            wait_cnt       <= '0;
            pready         <= 1'b1;
            pslverr        <= 1'b0;
            prdata         <= '0;
            latched_addr   <= '0;
            latched_wdata  <= '0;
            latched_pwrite <= 1'b0;
            foreach (mem[i]) mem[i] <= '0;

        end else begin

            case (state)

                // ==============================================================
                // IDLE: bus rảnh, pready=1
                // Khi master bắt đầu (psel=1, penable=0):
                //   - latch addr/data/ctrl
                //   - latch wait_cycles_nxt vào register (đây là thời điểm
                //     duy nhất wait_cycles được cập nhật)
                //   - sang SETUP
                // ==============================================================
                IDLE: begin
                    pready   <= 1'b1;
                    pslverr  <= 1'b0;
                    wait_cnt <= '0;

                    if (psel && !penable) begin
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= wait_cycles_nxt; // latch comb wire
                        state          <= SETUP;
                    end
                end

                // ==============================================================
                // SETUP: psel=1, penable=0 (đúng 1 cycle theo APB spec)
                // wait_cycles đã được latch từ posedge IDLE → đọc giá trị đúng.
                //
                // Tại đây:
                //   - Nếu wait_cycles == 0: giữ pready=1 (no-wait slave)
                //   - Nếu wait_cycles >  0: kéo pready=0 (báo master phải đợi)
                //
                // Khi penable assert:
                //   - wait=0: mem_op + IDLE
                //   - wait>0: sang ACCESS_WAIT với wait_cnt=0
                // ==============================================================
                SETUP: begin
                    pslverr <= 1'b0;

                    if (!psel) begin
                        // Master hủy
                        pready <= 1'b1;
                        state  <= IDLE;

                    end else begin
                        // Báo hiệu sẵn sàng hay không cho master
                        pready <= (wait_cycles == 8'd0) ? 1'b1 : 1'b0;

                        if (penable) begin
                            // Master vào ACCESS phase
                            if (wait_cycles == 8'd0) begin
                                // No-wait: xong ngay
                                pready <= 1'b1;
                                do_mem_op();
                                state  <= IDLE;
                            end else begin
                                // Wait-state: sang ACCESS_WAIT
                                // pready đã được set = 0 ở trên
                                // wait_cnt = 0 (đã clear ở IDLE, không thay đổi)
                                state <= ACCESS_WAIT;
                            end
                        end
                        // else: penable vẫn =0, ở lại SETUP
                    end
                end

                // ==============================================================
                // ACCESS_WAIT: psel=1, penable=1, pready=0
                //
                // wait_cnt đếm từ 0 đến wait_cycles-1.
                // Mỗi posedge: nếu chưa đủ → tăng wait_cnt, giữ pready=0.
                //              nếu đủ     → mem_op, pready=1, về IDLE.
                //
                // Số cycle ở lại ACCESS_WAIT = wait_cycles (vì wait_cycles >= 1).
                // ==============================================================
                ACCESS_WAIT: begin

                    if (!psel) begin
                        pready <= 1'b1;
                        state  <= IDLE;

                    end else if (!penable) begin
                        // Illegal per spec – defensive: re-latch như SETUP mới
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= wait_cycles_nxt;
                        wait_cnt       <= '0;
                        pready         <= 1'b1;
                        state          <= SETUP;

                    end else begin
                        // Đang đếm wait
                        if (wait_cnt < wait_cycles - 8'd1) begin
                            // Chưa đủ
                            pready   <= 1'b0;
                            pslverr  <= 1'b0;
                            wait_cnt <= wait_cnt + 8'd1;
                        end else begin
                            // Đủ rồi: wait_cnt == wait_cycles-1
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

    // =========================================================================
    // Memory operation (task gọi được trong always_ff với SystemVerilog)
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