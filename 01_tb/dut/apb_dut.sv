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
    
    logic [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];
    
    logic [7:0] wait_cycles;
    logic [7:0] wait_cnt;
    logic       transaction_done;

    // =============================================
    // Random Wait States Generation
    // =============================================
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            wait_cycles <= '0;
        end else if (psel && !penable) begin        // Setup Phase
            wait_cycles <= $urandom_range(0, MAX_WAIT);
        end
    end

    // =============================================
    // Main APB Control Logic
    // =============================================
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            pready     <= 1'b0;
            pslverr    <= 1'b0;
            prdata     <= '0;
            wait_cnt   <= '0;
            
            // Initialize SRAM
            foreach (mem[i]) mem[i] <= '0;   // hoặc 32'hDEADBEEF
        end 
        else begin
            
            pslverr <= 1'b0;
            pready  <= 1'b0;

            if (psel && penable) begin
                
                if (wait_cnt < wait_cycles) begin
                    // Still in wait states
                    wait_cnt <= wait_cnt + 1;
                end 
                else begin
                    // Transaction completed
                    pready   <= 1'b1;
                    wait_cnt <= '0;

                    if (paddr >= MEM_SIZE) begin
                        // Address out of range → Error
                        pslverr <= 1'b1;
                        prdata  <= 32'hDEADBEEF;
                    end 
                    else if (pwrite) begin
                        // ============== WRITE ==============
                        mem[paddr[MEM_DEPTH-1:0]] <= pwdata;
                    end 
                    else begin
                        // ============== READ ==============
                        prdata <= mem[paddr[MEM_DEPTH-1:0]];
                    end
                end
            end
        end
    end

    // Optional: Drive prdata only when selected (good practice)
    // assign prdata = (psel) ? mem[paddr[MEM_DEPTH-1:0]] : 'z;

endmodule