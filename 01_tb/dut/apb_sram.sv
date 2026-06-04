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
                        end else begin
                            // Giữ pready chuẩn cho pha SETUP (0 nếu có wait, 1 nếu no-wait)
                            pready <= (wait_cycles == 8'd0) ? 1'b1 : 1'b0;
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