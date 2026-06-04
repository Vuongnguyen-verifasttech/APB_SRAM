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

                // ------------------------------------------------------------
                IDLE: begin
                    pready   <= 1'b1;
                    pslverr  <= 1'b0;
                    wait_cnt <= '0; // Giữ counter reset ở IDLE

                    if (psel && !penable) begin
                        latched_addr   <= paddr;
                        latched_wdata  <= pwdata;
                        latched_pwrite <= pwrite;
                        wait_cycles    <= $urandom_range(0, MAX_WAIT);
                        state          <= SETUP;
                    end
                end

                // ------------------------------------------------------------
                SETUP: begin
                    pslverr <= 1'b0;

                    if (!psel) begin
                        pready <= 1'b1;
                        state  <= IDLE;
                    end else begin
                        if (penable) begin
                            if (wait_cycles == 8'd0) begin
                                // Không có wait state -> Xong luôn trong 1 clock
                                pready <= 1'b1;
                                do_mem_op();
                                state  <= IDLE;
                            end else begin
                                // Có wait state -> Hạ pready xuống 0, chuyển sang WAIT
                                pready   <= 1'b0; 
                                wait_cnt <= '0; // Đảm bảo reset counter tại đây
                                state    <= ACCESS_WAIT;
                            end
                        end 
                    
                end

                // ------------------------------------------------------------
                ACCESS_WAIT: begin
                    if (!psel) begin
                        pready <= 1'b1;
                        state  <= IDLE;
                    end else if (!penable) begin
                        // Master vi phạm protocol, tự bảo vệ DUT
                        pready <= 1'b1;
                        state  <= IDLE;
                    end else begin
                        // Kiểm tra xem đã đếm đủ số chu kỳ chờ chưa
                        if (wait_cnt < wait_cycles - 8'd1) begin
                            pready   <= 1'b0; // Giữ pready thấp
                            wait_cnt <= wait_cnt + 8'd1; // Tăng counter một cách tuần tự
                        end else begin
                            // Đã đợi đủ số chu kỳ -> Kéo pready lên 1 để kết thúc
                            pready   <= 1'b1;
                            do_mem_op(); // Thực thi đọc/ghi vào bộ nhớ
                            wait_cnt <= '0;
                            state    <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
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