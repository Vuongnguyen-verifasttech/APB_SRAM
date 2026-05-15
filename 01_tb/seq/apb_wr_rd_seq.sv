//==============================================================================
// File          : apb_wr_rd_seq.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Write Read Sequence
//                 - Write a transaction to mem
//                 - Then read at the same addr whether it's same with write data or not
//                      
//
// Version       : 1.0
// Date          : 15-May-2026
//==============================================================================
`ifndef APB_WR_RD_SEQ_SV
`define APB_WR_RD_SEQ_SV

class apb_wr_rd_seq extends apb_base_seq;

    `uvm_object_utils(apb_wr_rd_seq)

    rand int num_tx = 256;     // Số lần Write-Read

    function new(string name = "apb_wr_rd_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_transaction wr_trans, rd_trans;

        repeat(num_tx) begin
            // ==================== WRITE ====================
            wr_trans = apb_transaction::type_id::create("wr_trans");
            
            start_item(wr_trans);
            assert(wr_trans.randomize() with {pwrite == 1;});
            finish_item(wr_trans);

            `uvm_info(get_type_name(), $sformatf("WRITE: ADDR=0x%8h DATA=0x%8h", 
                      wr_trans.paddr, wr_trans.pwdata), UVM_MEDIUM)

            // ==================== READ same address ====================
            rd_trans = apb_transaction::type_id::create("rd_trans");
            
            start_item(rd_trans);
            assert(rd_trans.randomize() with {
                pwrite == 0;
                paddr == wr_trans.paddr;     // Đọc lại cùng địa chỉ
            });
            finish_item(rd_trans);

            `uvm_info(get_type_name(), $sformatf("READ : ADDR=0x%8h RDATA=0x%8h", 
                      rd_trans.paddr, rd_trans.prdata), UVM_MEDIUM)
        end
    endtask

endclass : apb_wr_rd_seq

`endif