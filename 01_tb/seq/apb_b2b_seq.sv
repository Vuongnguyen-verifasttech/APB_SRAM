//==============================================================================
// File          : apb_b2b_seq.sv
// Description   : True Back-to-Back Sequence - Transaction liên tiếp không idle
// Testplan ID   : APB_10
//==============================================================================

`ifndef APB_B2B_SEQ_SV
`define APB_B2B_SEQ_SV

class apb_b2b_seq extends apb_base_seq;

    `uvm_object_utils(apb_b2b_seq)

    // Khai báo p_sequencer đúng cách
    `uvm_declare_p_sequencer(uvm_sequencer#(apb_transaction))

    rand int num_tx;

    constraint num_tx_c {
        num_tx inside {[30:80]};
    }

    // Handle to driver
    apb_driver drv;

    function new(string name = "apb_b2b_seq");
        super.new(name);
    endfunction

    virtual task pre_body();
        // Lấy driver từ config_db bằng cách sử dụng m_sequencer làm context
        if (!uvm_config_db#(apb_driver)::get(m_sequencer, "", "driver", drv)) begin
            `uvm_fatal(get_type_name(), "Cannot get driver from config_db! B2B mode will not work.");
        end
        if(!randomize()) begin
          `uvm_error(get_type_name(),"Randomize num_tx fail in stress sequence");
       end
    endtask

    virtual task body();
        apb_transaction tr;

        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("           START TRUE BACK-TO-BACK SEQUENCE - %0d TRANSACTIONS", num_tx), UVM_NONE);
        `uvm_info(get_type_name(), "           (No idle cycle between transactions)", UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);


         drv.b2b_mode = 1; //improve code coverage 
        /*

        // Bật B2B mode
        if (drv != null) begin
            drv.b2b_mode = 1;
            `uvm_info(get_type_name(), "→ B2B mode ENABLED in driver", UVM_MEDIUM);
        end else begin
            `uvm_warning(get_type_name(), "Driver is null, cannot enable B2B mode");
        end
        */

        repeat(num_tx) begin
            tr = apb_transaction::type_id::create("tr");

            start_item(tr);

            // Thay vì dùng assert, ta dùng if (!tr.randomize())
            if (!tr.randomize()) begin
            // pragma coverage off
            `uvm_error(get_type_name(), "Randomize failed in B2B sequence!")
            // pragma coverage on
            end
            //assert(tr.randomize())
            //else `uvm_error(get_type_name(), "Randomize failed in B2B sequence!");

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

        // Tắt B2B mode
        if (drv != null) begin
            drv.b2b_mode = 0;
            `uvm_info(get_type_name(), "→ B2B mode DISABLED in driver", UVM_MEDIUM);
        end

        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
        `uvm_info(get_type_name(), $sformatf("           BACK-TO-BACK SEQUENCE COMPLETED (%0d transactions)", num_tx), UVM_NONE);
        `uvm_info(get_type_name(), "============================================================", UVM_NONE);
    endtask

endclass : apb_b2b_seq

`endif
