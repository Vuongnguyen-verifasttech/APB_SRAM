`ifndef APB_PKG_SV
`define APB_PKG_SV

package apb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // CHỈ include các file CLASS (UVM Components)
    // Thứ tự include cực kỳ quan trọng: Cái nào dùng trước include trước
    `include "apb_transaction.sv"
    `include "apb_driver.sv"
    `include "apb_monitor.sv"
    `include "apb_agent.sv"
    `include "apb_scoreboard.sv"
    `include "apb_env.sv"
    `include "apb_base_seq.sv"
    `include "apb_write_seq.sv"
    `include "apb_read_seq.sv"
    `include "apb_base_test.sv"

endpackage
`endif
