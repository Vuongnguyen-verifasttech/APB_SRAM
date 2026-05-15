//==============================================================================
// File          : apb_driver.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Driver definition
//                 - Handles the driving of APB transactions to the DUT
//                      
//
// Version       : 1.0
// Date          : 12-May-2026
//==============================================================================


`ifndef APB_BASE_TEST_SV
`define APB_BASE_TEST_SV

class apb_base_test extends uvm_test;

    `uvm_component_utils(apb_base_test)

    apb_env env;
    apb_write_seq write_seq;
    apb_read_seq read_seq; 
    apb_wr_rd_seq wr_rd_sq;

    function new(string name = "apb_base_test", uvm_component parent = null); // thieu dau = & ;
        super.new(name, parent);
    endfunction
    
     virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env=apb_env::type_id::create("env",this);
        `uvm_info(get_type_name(), "Build phase completed", UVM_MEDIUM)
    endfunction 
    
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "==============START APB TEST =================", UVM_NONE)

        // Create Sequence 

        write_seq = apb_write_seq::type_id::create("write_seq");
        read_seq = apb_read_seq::type_id::create("read_seq");
        wr_rd_seq = apb_wr_rd_seq::type_id::create("wr_rd_seq");

        // Run Sequence
        repeat(2) begin 
            write_seq.start(env.agent.sequencer);
            read_seq.start(env.agent.sequencer);
            wr_rd_seq.start(env.agent.sequencer);
        end
        `uvm_info(get_type_name(), "=== All sequences completed ===", UVM_NONE)

        phase.drop_objection(this);   // Kết thúc test
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "APB Base Test completed", UVM_LOW)
    endfunction

endclass : apb_base_test

`endif
    
