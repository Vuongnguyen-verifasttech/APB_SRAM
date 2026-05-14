`ifndef APB_PKG_SV
`define APB_PKG_SV

package apb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Include tất cả các file theo thứ tự
    `include "interface/apb_if.sv"
    `include "env/apb_agent/apb_transaction.sv"
    `include "env/apb_agent/apb_driver.sv"
    `include "env/apb_agent/apb_monitor.sv"
    `include "env/apb_agent/apb_agent.sv"
    `include "env/apb_scoreboard.sv"
    `include "env/apb_env.sv"
    `include "seq/apb_base_seq.sv"
    `include "seq/apb_write_seq.sv"
    `include "seq/apb_read_seq.sv"
    `include "test/apb_base_test.sv"

endpackage

`endif