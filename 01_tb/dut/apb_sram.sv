`timescale 1ns/1ps

module apb_sram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_DEPTH  = 10,
    parameter int MAX_WAIT   = 8
)(
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

localparam int MEM_SIZE = (1 << MEM_DEPTH);

typedef enum logic [1:0] {
    IDLE,
    SETUP,
    ACCESS_WAIT
} apb_state_e;

apb_state_e state;

logic [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];

logic [ADDR_WIDTH-1:0] latched_addr;
logic [DATA_WIDTH-1:0] latched_wdata;
logic                  latched_pwrite;

logic [7:0] wait_cycles;
logic [7:0] wait_cnt;

task automatic do_mem_op();
begin
    if (latched_addr >= MEM_SIZE) begin
        pslverr <= 1'b1;
        prdata  <= 'hDEAD_BEEF;
    end
    else if (latched_pwrite) begin
        mem[latched_addr[MEM_DEPTH-1:0]] <= latched_wdata;
        pslverr <= 1'b0;
    end
    else begin
        prdata  <= mem[latched_addr[MEM_DEPTH-1:0]];
        pslverr <= 1'b0;
    end
end
endtask

integer rand_wait;

always_ff @(posedge pclk or negedge presetn) begin
    if(!presetn) begin

        state          <= IDLE;
        pready         <= 1'b1;
        pslverr        <= 1'b0;
        prdata         <= '0;

        wait_cycles    <= '0;
        wait_cnt       <= '0;

        latched_addr   <= '0;
        latched_wdata  <= '0;
        latched_pwrite <= '0;

        foreach(mem[i])
            mem[i] <= '0;

    end
    else begin

        case(state)

        //--------------------------------------------------
        IDLE:
        begin
            pready  <= 1'b1;
            pslverr <= 1'b0;

            if(psel && !penable) begin

                latched_addr   <= paddr;
                latched_wdata  <= pwdata;
                latched_pwrite <= pwrite;

                rand_wait = $urandom_range(0, MAX_WAIT);

                wait_cycles <= rand_wait;
                wait_cnt    <= rand_wait;

                state <= SETUP;
            end
        end

        //--------------------------------------------------
        SETUP:
        begin

            if(!psel) begin
                state  <= IDLE;
                pready <= 1'b1;
            end

            else if(penable) begin

                if(wait_cnt == 1) begin

                    pready <= 1'b1;

                    do_mem_op();

                    state <= IDLE;
                end
                else begin

                    pready <= 1'b0;

                    state <= ACCESS_WAIT;
                end
            end
        end

        //--------------------------------------------------
        ACCESS_WAIT:
begin
    if(!psel || !penable) begin
        pready <= 1'b1;
        state  <= IDLE;
    end
    else begin
        if(wait_cnt > 2) begin
            wait_cnt <= wait_cnt - 1;
            pready   <= 1'b0;
        end
        else if (wait_cnt == 2) begin
            wait_cnt <= wait_cnt - 1;
            pready   <= 1'b1; // <-- Bật sớm 1 clock để chu kỳ sau (khi wait_cnt=1) pready trên bus sẽ bằng 1!
        end
        else begin // Khi wait_cnt == 1 (Chu kỳ ACCESS cuối cùng thực sự trên bus với PREADY=1)
            do_mem_op();
            wait_cnt <= '0;
            state <= IDLE;
        end
    end
end
        default:
            state <= IDLE;

        endcase
    end
end

endmodule