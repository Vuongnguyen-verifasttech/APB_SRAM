`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

class apb_coverage extends uvm_subscriber #(apb_transaction);
    `uvm_component_utils(apb_coverage)

    apb_transaction tr;

    covergroup cg_apb;
        option.per_instance = 1;
        option.goal = 95;

        // 1. Transaction Type
        cp_type: coverpoint tr.pwrite {
            bins write = {1};
            bins read  = {0};
        }

        // 2. Address
        cp_addr: coverpoint tr.paddr[9:0] {
            bins valid[] = {[0:1023]};
        }

        // 3. Wait States
        cp_wait: coverpoint tr.wait_cycles {
            bins zero_b   = {0};
            bins low_b    = {[1:3]};
            bins medium_b = {[4:6]};
            bins high_b   = {[7:8]}; // kh dc dat ten giong bien co dinh
        }

        // 4. Error
        cp_error: coverpoint tr.pslverr {
            bins no_error = {0};
            bins has_error = {1};
        }

        // Cross Coverage
        cross_type_wait: cross cp_type, cp_wait;
        cross_type_addr : cross cp_type, cp_addr;
        cross_error     : cross cp_type, cp_error;

    endgroup : cg_apb

    function new(string name = "apb_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_apb = new();
    endfunction

    virtual function void write(apb_transaction t);
        tr = t;
        if (tr != null) begin
            cg_apb.sample();
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), 
            $sformatf("=== FUNCTIONAL COVERAGE = %.2f%% ===", 
                      cg_apb.get_inst_coverage()), UVM_NONE);
    endfunction

endclass : apb_coverage

`endif
