//==============================================================================
// File          : apb_reset_seq.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Reset Sequence definition
//                 - generate reset signals for the APB interface
//                      
//
// Version       : 1.0
// Date          : 21-May-2026
//==============================================================================

`ifndef APB_RESET_SEQ_SV
`define APB_RESET_SEQ_SV

class apb_reset_seq extends apb_base_seq;

    `uvm_object_utils(apb_reset_seq)

    rand int reset_duration;   // Số chu kỳ giữ reset active-low

    // Constraint
    constraint reset_c {
        reset_duration inside {[5:20]};   // Giữ reset từ 5 đến 20 cycles
    }

    function new(string name = "apb_reset_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_transaction tr;

        `uvm_info(get_type_name(), "=== STARTING APB RESET SEQUENCE ===", UVM_NONE)

        //===============================================
        // 1. Assert Reset (presetn = 0)
        //===============================================
        `uvm_info(get_type_name(), $sformatf("Asserting presetn = 0 for %0d cycles", reset_duration), UVM_MEDIUM);

        repeat(reset_duration) begin
            @(p_sequencer.vif.driver_cb);
            p_sequencer.vif.driver_cb.presetn <= 1'b0;   // Assert reset
        end

        //===============================================
        // 2. Deassert Reset (presetn = 1)
        //===============================================
        @(p_sequencer.vif.driver_cb);
        p_sequencer.vif.driver_cb.presetn <= 1'b1;   // Deassert reset

        `uvm_info(get_type_name(), "Deasserted reset. Waiting for DUT to stabilize...", UVM_MEDIUM);

        repeat(15) @(p_sequencer.vif.driver_cb);   // Chờ DUT ổn định sau reset

        //===============================================
        // 3. Gửi vài transaction sau reset để kiểm tra
        //===============================================
        `uvm_info(get_type_name(), "Sending 2 write + 2 read transactions after reset...", UVM_MEDIUM);

        // --- 2 Write transactions ---
        repeat(2) begin
            tr = apb_transaction::type_id::create("tr");

            start_item(tr);
            assert(tr.randomize() with { pwrite == 1; })
            else `uvm_error(get_type_name(), "Randomize failed for WRITE transaction!");
            tr.seq_name = "RESET_SEQ_WRITE";
            finish_item(tr);
        end

        // --- 2 Read transactions ---
        repeat(2) begin
            tr = apb_transaction::type_id::create("tr");

            start_item(tr);
            assert(tr.randomize() with { pwrite == 0; })
            else `uvm_error(get_type_name(), "Randomize failed for READ transaction!");
            tr.seq_name = "RESET_SEQ_READ";
            finish_item(tr);
        end

        `uvm_info(get_type_name(), "=== APB RESET SEQUENCE COMPLETED ===", UVM_NONE);
    endtask

endclass : apb_reset_seq

`endif