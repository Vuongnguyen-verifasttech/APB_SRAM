//==============================================================================
// File          : apb_stress_seq.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Stress Sequence
//                 -  Check the behavior of the DUT under heavy load by generating a large number of transactions in quick succession
//                 -  Mix of read and write transactions to random addresses
//                      , random wait states
//
// Version       : 1.0
// Date          : 21-May-2026
//==============================================================================
`ifndef APB_STRESS_SEQ_SV
`define APB_STRESS_SEQ_SV

class apb_stress_seq extends apb_base_seq;
    `uvm_object_utils(apb_stress_seq)

    // Random the number of transaction stress
    rand int num_tx;
    constraint num_tx_c {
        num_tx inside {[300:800]};
    }

    function new(string name = "apb_stress_seq");
        super.new(name);
    endfunction 

    virtual task body();
        apb_transaction tr;

        // Banner bắt đầu - Dễ nhìn khi chạy nhiều sequence
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("           START APB_12:  STRESS SEQUENCE - %0d TRANSACTIONS", num_tx), UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);

        repeat(num_tx) begin 
            tr = apb_transaction::type_id::create("tr");
            start_item(tr);

            // random full khong rang buoc cm j het

            assert(tr.randomize())
            else `uvm_error(get_type_name(), " Randomize fail in stress sequences ");

            tr.seq_name = "STRESS_SEQ";
            finish_item(tr);

            // Log info transaction dc gui

            if (tr.pwrite) begin
                `uvm_info(get_type_name(), 
                    $sformatf("   [STRESS] WRITE  ADDR=0x%8h  DATA=0x%8h  WAIT=%0d", 
                              tr.paddr, tr.pwdata, tr.wait_cycles), UVM_HIGH);
           end  else begin
                `uvm_info(get_type_name(), 
                    $sformatf("   [STRESS] READ   ADDR=0x%8h  WAIT=%0d", 
                              tr.paddr, tr.wait_cycles), UVM_HIGH);
        end
        end

        // Banner kết thúc
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("           COMPLETED: APB_12: STRESS SEQUENCE  (%0d transactions)", num_tx), UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
    endtask

endclass: apb_stress_seq

`endif
