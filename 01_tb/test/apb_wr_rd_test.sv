`ifndef APB_WR_RD_TEST_SV
`define APB_WR_RD_TEST_SV
// Test nay dg co van de o dau test, phan sau thi okla: fix after
class apb_wr_rd_test extends apb_base_test;
    `uvm_component_utils(apb_wr_rd_test)

    function new(string name = "apb_wr_rd_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task main_phase(uvm_phase phase);
        apb_wr_rd_seq seq;
        seq = apb_wr_rd_seq::type_id::create("seq");

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "=== [TEST_START] Running apb_wr_rd_test ===", UVM_LOW)
        
        seq.start(env.agent.sequencer);
        
        `uvm_info(get_type_name(), "=== [TEST_DONE] apb_wr_rd_test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

`endif