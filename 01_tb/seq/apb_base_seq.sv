//==============================================================================
// File          : apb_base_seq.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Base Sequence
//                 -  
//                      
//
// Version       : 1.0
// Date          : 14-May-2026
//==============================================================================

`ifndef APB_BASE_SEQ_SV
`define APB_BASE_SEQ_SV

class apb_base_seq extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_base_seq)

    function new(string name = "apb_base_seq"); 
        super.new(name); //object ne chi co name thoi
    endfunction

    // Main task to call child classes

    virtual task body(); 
        `uvm_info(get_type_name(), "Base sequence body started", UVM_MEDIUM)
    endtask

endclass : apb_base_seq

`endif
