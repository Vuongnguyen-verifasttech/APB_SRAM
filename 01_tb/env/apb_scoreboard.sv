//==============================================================================
// File          : apb_scoreboard.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Monitor definition
//                 - capture value from monitor, compare with reference model
//                      
//
// Version       : 1.0
// Date          : 13-May-2026
//==============================================================================

`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV

class apb_scoreboard extends uvm_scoreboard; 
    
    `uvm_component_utils(apb_scoreboard)
    
    // Analysis port receive data from monitor 
    uvm_analysis_imp #(apb_transaction, apb_scoreboard) mon_imp;

    // Reference model (memory model)
    logic [31:0] mem_model [bit[31:0]];

    // ==================== COUNTERS ====================
    int total_transactions = 0;
    int write_transactions = 0;
    int read_transactions  = 0;
    int error_transactions = 0;
    int passed_transactions = 0;
    int failed_transactions = 0;

    //Contructor
    function new(string name = "apb_scoreboard", uvm_component parent = null); 
        super.new(name, parent);
        mon_imp = new("mon_imp", this);
    endfunction

    // Ham Write automatic goi khi 1 Tran duoc gui den 

    virtual function void write(apb_transaction tr); 
        string seq_info;
        total_transactions++;
        tr.trans_id = total_transactions;
        seq_info = (tr.seq_name != "UNKNOWN_SEQ") ? $sformatf("[%s]", tr.seq_name) : "";

        if(tr.pslverr) begin
            error_transactions++; 
            `uvm_warning(get_type_name(), $sformatf("T#%0d [SLVERR] ADDR=0x%8h", tr.trans_id, tr.paddr))
            return;
        end
        if (tr.pwrite) begin 
            // ============== WRITE ==========================
            write_transactions++;
            tr.trans_id = total_transactions;   // Gán số thứ tự
            mem_model[tr.paddr] = tr.pwdata;
            passed_transactions++;
            `uvm_info(get_type_name(), 
            $sformatf("T#%0d [WRITE] ADDR=0x%8h DATA=0x%8h", 
                      tr.trans_id, tr.paddr, tr.pwdata), UVM_HIGH);
        end else begin 
            // ============== READ ===========================
           logic [31:0] expected ; 
           read_transactions++;
           expected = mem_model.exists(tr.paddr) ? mem_model[tr.paddr] : 32'h0;

            if (tr.prdata === expected) begin
                passed_transactions++;
                `uvm_info(get_type_name(), 
                $sformatf("T#%0d [READ PASS] ADDR=0x%8h RDATA=0x%8h", 
                          tr.trans_id, tr.paddr, tr.prdata), UVM_MEDIUM);
            end else begin
                failed_transactions++;
                `uvm_error(get_type_name(), 
                $sformatf("T#%0d [READ FAIL] ADDR=0x%8h | Exp=0x%8h | Act=0x%8h", 
                          tr.trans_id, tr.paddr, expected, tr.prdata));
            end
        end
    endfunction

    // Báo cáo cuối cùng
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(get_type_name(), "\n", UVM_NONE)
        `uvm_info(get_type_name(), "================== SCOREBOARD REPORT ==================", UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Total Transactions   : %0d", total_transactions), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Write Transactions   : %0d", write_transactions), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Read Transactions    : %0d", read_transactions), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Error Transactions   : %0d", error_transactions), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Passed Transactions  : %0d", passed_transactions), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Failed Transactions  : %0d", failed_transactions), UVM_NONE)
        
        if (failed_transactions == 0)
            `uvm_info(get_type_name(), "                  *** TEST PASSED ***", UVM_NONE)
        else
            `uvm_error(get_type_name(), "                  *** TEST FAILED ***")
            
        `uvm_info(get_type_name(), "===================================================\n", UVM_NONE)
    endfunction

endclass
`endif
