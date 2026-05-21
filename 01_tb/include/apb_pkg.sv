`ifndef APB_PKG_SV
`define APB_PKG_SV

package apb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 1. Các class cơ bản
    `include "apb_transaction.sv"
    `include "apb_driver.sv"
    `include "apb_monitor.sv"
    `include "apb_agent.sv"
    `include "apb_scoreboard.sv"

    // 2. Coverage (phải trước env)
    `include "apb_coverage.sv"

    // 3. Environment
    `include "apb_env.sv"

    // 4. Sequences
    `include "apb_base_seq.sv"
    `include "apb_write_seq.sv"
    `include "apb_read_seq.sv"
    `include "apb_wr_rd_seq.sv"
    `include "apb_reset_seq.sv"
    `include "apb_illegal_addr_seq.sv"

    // 5. Test
    `include "apb_base_test.sv"

endpackage : apb_pkg

`endif
