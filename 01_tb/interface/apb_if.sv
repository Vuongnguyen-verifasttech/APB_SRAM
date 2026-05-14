//==============================================================================
// File          : apb_if.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Interface definition
//                 - Defines the APB signals and clocking blocks
//                 - Provides modports for driver, monitor, and DUT connections                
//
// Version       : 1.0
// Date          : 12-May-2026
//==============================================================================
`ifndef APB_IF_SV
`define APB_IF_SV  
interface apb_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH =32)
    (input logic pclk,
    input logic presetn);

//======= APB signal ============================
    logic [ADDR_WIDTH-1:0] paddr;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [DATA_WIDTH-1:0] prdata;
    logic psel;
    logic penable;
    logic pwrite;
    logic pready;
    logic pslverr;

//======== CLocking blocks=======================
// Clocking  block cho driver 
// Driver phải tạo stimulus (chủ động drive bus), nên cần khai báo output cho các signal nó drive
// Driver cũng cần nhận phản hồi từ Slave (pready, prdata, pslverr) để biết khi nào transaction kết thúc → phải có input.
    clocking drv_cb @(posedge pclk);
        default input #1step output #0; // #1step: sample truowcs khi clock edge 1 chut --> tranh race condition
                                        // #0: drive ngay lập tức khi có clock edge, không delay
        output  psel, penable, pwrite, paddr, pwdata;
        input  prdata, pready, pslverr;

    endclocking : drv_cb 

// Clocking block cho monitor
// Monitor chỉ quan sát bus, không được phép drive bất kỳ signal nào → chỉ cần input
    clocking mon_cb @(posedge pclk);
        default input #1step; 
        input  paddr, psel, penable, pwrite, pwdata,
               prdata, pready, pslverr;
    endclocking : mon_cb

//======== Modport ==============================
    modport driver (  clocking drv_cb, input presetn);
    modport monitor (clocking mon_cb, input presetn);
    //modports of driver & monitor only include clocking blocks and reset because other signals are included in clocking blocks. 
    //====== Modport cho DUT ============================
    modport dut (input pclk, presetn,
                 input psel, penable, pwrite, paddr, pwdata,
                 output prdata, pready, pslverr); 
endinterface : apb_if
`endif 