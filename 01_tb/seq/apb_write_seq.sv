//==============================================================================
// File          : apb_write_seq.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Write Sequence
//                 -  
//                      
//
// Version       : 1.0
// Date          : 14-May-2026


`ifndef APB_WRITE_SEQ_SV
`define APB_WRITE_SEQ_SV

class apb_write_seq extends apb_base_seq;
    `uvm_object_utils(apb_write_seq)

    rand int num_tx = 20;

    function new(string name = "apb_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_transaction tr;
        repeat(num_tx) begin 
                tr = apb_transaction::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize() with {pwrite == 1;});
                finish_item(tr);
        `uvm_info(get_type_name(), $sformatf("TASK WRITE: Sent Write: ADDR = 0x%8h, DATA = 0x%8h", tr.paddr, tr.pwdata), UVM_MEDIUM)
        end
    endtask

endclass
`endif 
