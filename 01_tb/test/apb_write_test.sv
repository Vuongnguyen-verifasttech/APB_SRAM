`ifndef APB_WRITE_TEST_SV
`define APB_WRITE_TEST_SV

class apb_write_test extends apb_base_test;
    `uvm_component_utils(apb_write_test)

    function new(string name = "apb_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task main_phase(uvm_phase phase);
        apb_write_seq seq;
        seq = apb_write_seq::type_id::create("seq");

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "=== [TEST_START] Running apb_write_test ===", UVM_LOW)
        
        // Khởi chạy duy nhất kịch bản ghi dữ liệu trên bộ sequencer của agent
        seq.start(env.agent.sequencer);
        
        `uvm_info(get_type_name(), "=== [TEST_DONE] apb_write_test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

`endif