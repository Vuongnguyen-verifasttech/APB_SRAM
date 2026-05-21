//==============================================================================
// File          : apb_b2b_seq.sv
// Description   : True Back-to-Back Sequence (không idle giữa transaction)
// Testplan ID   : APB_10
//==============================================================================

`ifndef APB_B2B_SEQ_SV
`define APB_B2B_SEQ_SV

class apb_b2b_seq extends apb_base_seq;

    `uvm_object_utils(apb_b2b_seq)

    rand int num_tx;

    constraint num_tx_c {
        num_tx inside {[30:80]};
    }

    function new(string name = "apb_b2b_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_transaction tr;

        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("           START APB_10: TRUE BACK-TO-BACK SEQUENCE - %0d TRANSACTIONS", num_tx), UVM_NONE);
        `uvm_info(get_type_name(), "           (No idle cycle between transactions)", UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);

        // Bật B2B mode trong driver
        if (p_sequencer != null && p_sequencer.driver != null)
            p_sequencer.driver.b2b_mode = 1;

        repeat(num_tx) begin
            tr = apb_transaction::type_id::create("tr");

            start_item(tr);
            assert(tr.randomize())
            else `uvm_error(get_type_name(), "Randomize failed in B2B sequence!");

            tr.seq_name = "B2B_SEQ";
            finish_item(tr);

            if (tr.pwrite) begin
                `uvm_info(get_type_name(), 
                    $sformatf("   [B2B] WRITE  ADDR=0x%8h  DATA=0x%8h  WAIT=%0d", 
                              tr.paddr, tr.pwdata, tr.wait_cycles), UVM_LOW);
            end else begin
                `uvm_info(get_type_name(), 
                    $sformatf("   [B2B] READ   ADDR=0x%8h  WAIT=%0d", 
                              tr.paddr, tr.wait_cycles), UVM_LOW);
            end
        end

        // Tắt B2B mode sau khi chạy xong
        if (p_sequencer != null && p_sequencer.driver != null)
            p_sequencer.driver.b2b_mode = 0;

        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("         COMPLETED APB_10:  BACK-TO-BACK SEQUENCE (%0d transactions)", num_tx), UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
    endtask

endclass : apb_b2b_seq

`endif