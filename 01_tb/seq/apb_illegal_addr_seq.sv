//==============================================================================
// File          : apb_illegal_addr_seq.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Illegal Address Sequence
//                - Generate transactions with illegal addresses to test DUT's response
//                - Sent transactions with addresses outside the valid range and check for error responses
//                - DUT have to respond: pslverr = 1 & prdata = 32'hDEADBEEF 
//                 
//                      
//
// Version       : 1.0
// Date          : 21-May-2026
//==============================================================================


`ifndef APB_ILLEGAL_ADDR_SEQ_SV
`define APB_ILLEGAL_ADDR_SEQ_SV

class apb_illegal_addr_seq extends apb_base_seq;
    `uvm_object_utils(apb_illegal_addr_seq)

    rand int num_tx;

    constraint num_tc_c {
        num_tx inside {[5:20]};
    }

    function new(string name = "apb_illegal_addr_seq");
        super.new(name);
    endfunction 

    virtual task body();

        apb_transaction tr;

        `uvm_info(get_type_name(), "========================== START ILLEGAL ADDRESS TEST ====================================================" )

        repeat(num_tx) begin
            tr= apb_transaction::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with {
                paddr >= 32'h0000_0400; // Assuming valid address range is 0x0000_0000 to 0x0000_03FF
                pwrite inside {0, 1}; // Randomly choose between read and write
            })
            else `uvm_error(get_type_name(), "Failed to randomize transaction with illegal address");
            tr.seq_name = "ILLEGAL_ADDR_SEQ";
            finish_item(tr);
        end

            `uvm_info(get_type_name(), "============= ILLEGAL ADDRESS SEQUENCE COMPLETE======================")
    endtask
            
endclass : apb_illegal_addr_seq

`endif