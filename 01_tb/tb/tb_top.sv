`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import apb_pkg::*;     // Import package

module tb_top;

    bit pclk;
    bit presetn;

    // Clock Generation
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;   // 100 MHz
    end

    // Reset Generation
    initial begin
        presetn = 0;
        #35 presetn = 1;
    end

    // Interface
    apb_if apb_if(.pclk(pclk), .presetn(presetn));

    // DUT
    apb_sram #(
        .MEM_DEPTH(10),   // 256 locations
        .MAX_WAIT(8)
    ) dut (
        .pclk     (apb_if.pclk),
        .presetn  (apb_if.presetn),
        .psel     (apb_if.psel),
        .penable  (apb_if.penable),
        .pwrite   (apb_if.pwrite),
        .paddr    (apb_if.paddr),
        .pwdata   (apb_if.pwdata),
        .prdata   (apb_if.prdata),
        .pready   (apb_if.pready),
        .pslverr  (apb_if.pslverr)
    );

    initial begin
        // Set virtual interface cho Driver và Monitor
        uvm_config_db#(virtual apb_if.driver)::set(null, "*", "vif", apb_if.driver);
        uvm_config_db#(virtual apb_if.monitor)::set(null, "*", "vif", apb_if.monitor);

        `uvm_info("TB_TOP", "Starting APB UVM Testbench", UVM_LOW)

        run_test("apb_base_test");   // Chạy test mặc định
    end

endmodule