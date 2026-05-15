//==============================================================================
// File          : apb_driver.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Driver definition
//                 - Handles the driving of APB transactions to the DUT
//                      
//
// Version       : 1.0
// Date          : 12-May-2026
//==============================================================================

`ifndef APB_READ_SEQ_SV
`define APB_READ_SEQ_SV

class apb_read_seq extends apb_base_seq;

    `uvm_object_utils(apb_read_seq)

    rand int num_tx = 20;

    function new(string name = "apb_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_transaction tr;

        repeat(num_tx) begin
            tr = apb_transaction::type_id::create("tr");

            start_item(tr);
            assert(tr.randomize() with {pwrite == 0;});
            tr.seq_name = "READ_SEQ";
            finish_item(tr);

            `uvm_info(get_type_name(), $sformatf("TASK READ DATA : Sent Read: ADDR=0x%8h", tr.paddr), UVM_MEDIUM)
        end
    endtask

endclass : apb_read_seq

`endif
