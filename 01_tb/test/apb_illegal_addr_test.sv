`ifndef APB_ILLEGAL_ADDR_TEST_SV
`define APB_ILLEGAL_ADDR_TEST_SV

class apb_illegal_addr_test extends apb_base_test;
    `uvm_component_utils(apb_illegal_addr_test)

    function new(string name = "apb_illegal_addr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task main_phase(uvm_phase phase);
        apb_illegal_addr_seq seq;
        seq = apb_illegal_addr_seq::type_id::create("seq");

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "=== [TEST_START] Running apb_illegal_addr_test ===", UVM_LOW)
        
        seq.start(env.agent.sequencer);
        
        `uvm_info(get_type_name(), "=== [TEST_DONE] apb_illegal_addr_test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

`endif