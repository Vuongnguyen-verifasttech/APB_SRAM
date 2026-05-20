//==============================================================================
// File          : apb_coverage.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Coverage definition
//                 - Define covergroups to measure functional coverage of APB transactions
//                      
//
// Version       : 1.0
// Date          : 13-May-2026
//==============================================================================
`ifdef APB_COVERAGE_SV
`define APB_COVERAGE_SV

class apb_coverage extends uvm_subscriber #(apb_transaction); 
    `uvm_componnent_utils(apb_coverage)

    apb_transaction tr;

    //===================COVERGROUPS======================
    covergroup cg_apb_coverage;
        option.per_instance = 1;
        option.goal = 95; // Đặt mục tiêu coverage 95%
        
        // 1. Transaction types
        cp_type: coverpoint tr.pwrite {
            bins write = {1'b1};
            bin read = {1'b0};

        }

        // 2. Address Ranges
        cp_addr: coverpoint tr.paddr {
            bins valid = {[0:1023]}; // giá trị địa chỉ hợp lệ
           // bins illegal = {[1024:32'hFFFF_FFFF]}; // Giá trị địa chỉ không hợp lệ bên ngoài phạm vi bộ nhớ
        }

        // 3. wait state
        cg_wait_states: coverpoint tr.wait_cycles {
            bins zero = {0};
            bins low = {[1:3]};
            bins medium = {[4:7]};
            bin high = {[7:8]};
        }

        // 4. Error response
        cp_error: coverpoint tr.pslverr {
            bins no_error = {1'b0};
            bins error = {1'b1};
        }

        // Cross Coverage 
        cross_type_addr: cross cp_type, cp_addr;
        cross_type_wait: cross cp_type, cp_wait;
        cross_error_addr: cross cp_error, cp_addr;
        
    endgroup: cg_apb_coverage 

    // Constructor
    function new(string name ="apb_coverage", uvm_component parent = "null")
    
    super.new(name, parent);
    cg_apb_coverage = new();
    
    endfunction

    // Receive transaction từ monitor
    virtual function void write(apb_transaction t);
    tr = t;
    if (tr != null) begin
        cg_apb_coverage.sample();
    end
    endfunction 

// Report cuối test
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), 
            $sformatf("\n=== FUNCTIONAL COVERAGE REPORT ===\nCoverage = %.2f%%", 
                      cg_apb_coverage.get_inst_coverage()), UVM_NONE);
    endfunction

endclass : apb_coverage

`endif






