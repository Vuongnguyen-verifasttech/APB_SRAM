//==============================================================================
// File          : apb_illegal_addr_seq.sv
// Description   : Illegal Address Sequence - Test pslverr (APB_09)
//==============================================================================

`ifndef APB_ILLEGAL_ADDR_SEQ_SV
`define APB_ILLEGAL_ADDR_SEQ_SV

class apb_illegal_addr_seq extends apb_base_seq;

    `uvm_object_utils(apb_illegal_addr_seq)

    rand int num_tx;

    constraint num_tx_c {
        num_tx inside {[8:20]};
    }

    function new(string name = "apb_illegal_addr_seq");
        super.new(name);
    endfunction

    virtual task pre_body();
        if (!randomize()) begin
            `uvm_error(get_type_name(), "Randomize num_tx failed!");
        end
    endtask

    virtual task body();
        apb_transaction tr;

        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), "           START ILLEGAL ADDRESS SEQUENCE", UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);

        repeat(num_tx) begin
            tr = apb_transaction::type_id::create("tr");

            start_item(tr);
            assert(tr.randomize() with {
                paddr >= 32'h0000_0400;
                pwrite inside {0, 1};
            })
            else `uvm_error(get_type_name(), "Randomize illegal transaction failed!");

            tr.seq_name = "ILLEGAL_ADDR_SEQ";
            finish_item(tr);

            // Log chi tiết mỗi transaction
            `uvm_info(get_type_name(), 
                $sformatf(" Illegal Addr: 0x%8h  | WRITE=%b", tr.paddr, tr.pwrite), 
                UVM_LOW);
        end

        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), "           ILLEGAL ADDRESS SEQUENCE COMPLETED", UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("           Total illegal transactions: %0d", num_tx), UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
    endtask

endclass : apb_illegal_addr_seq

`endif
