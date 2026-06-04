`timescale 1ns/1ps

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

    // Sửa thành logic thông thường, cập nhật qua Non-blocking (<=)
    logic [7:0] wait_cycles;
    logic [7:0] wait_cnt;

    apb_state_e state;

    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            state          <= IDLE;
            wait_cycles    <= '0;   // Sửa thành <=
            wait_cnt       <= '0;   // Sửa thành <=
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
                // IDLE State
                // ------------------------------------------------------------
                IDLE: begin
                    pready   <= 1'b1;
                    pslverr  <= 1'b0;
                    wait_cnt <= '0; // Luôn giữ counter bằng 0 khi rảnh

                    if (psel && !penable) begin
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;

                        // Giá trị ngẫu nhiên được gán qua Non-blocking, 
                        // sẽ sẵn sàng ngay tại chu kỳ sau (SETUP)
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        state          <= SETUP;
                    end
                end

                // ------------------------------------------------------------
                // SETUP State (psel=1, penable=0)
                // ------------------------------------------------------------
                SETUP: begin
                    pslverr <= 1'b0;

                    if (!psel) begin
                        pready <= 1'b1;
                        state  <= IDLE;
                    end else begin
                        // Đặt pready dựa trên số chu kỳ wait_cycles đã chốt từ IDLE
                        pready <= (wait_cycles == 8'd0) ? 1'b1 : 1'b0;

                        if (penable) begin
                            if (wait_cycles == 8'd0) begin
                                // No-wait state: Thực hiện luôn và về IDLE
                                pready <= 1'b1;
                                do_mem_op();
                                state  <= IDLE;
                            end else begin
                                // Có Wait State: Chuyển sang ACCESS_WAIT.
                                // Không reset wait_cnt ở đây nữa vì IDLE đã làm rồi.
                                state  <= ACCESS_WAIT;
                            end
                        end
                    end
                end

                // ------------------------------------------------------------
                // ACCESS_WAIT State (psel=1, penable=1, pready=0)
                // ------------------------------------------------------------
                ACCESS_WAIT: begin
                    if (!psel) begin
                        pready <= 1'b1;
                        state  <= IDLE;
                    end else if (!penable) begin
                        // Phòng thủ lỗi vi phạm giao thức từ Master
                        pready         <= 1'b1;
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        wait_cnt       <= '0;
                        state          <= SETUP;
                    end else begin
                        // So sánh chuẩn counter dạng Non-blocking
                        if (wait_cnt < wait_cycles - 8'd1) begin
                            pready   <= 1'b0;
                            wait_cnt <= wait_cnt + 8'd1; // Tăng tuyến tính qua từng clock
                        end else begin
                            // Khi đếm đủ chu kỳ chờ
                            pready   <= 1'b1;
                            do_mem_op();
                            wait_cnt <= '0; // Reset counter chuẩn bị cho lượt sau
                            state    <= IDLE;
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

    // Task giữ nguyên logic gán tuần tự bên trong khối always_ff
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