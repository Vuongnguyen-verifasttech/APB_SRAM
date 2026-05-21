`ifndef APB_BASE_TEST_SV
`define APB_BASE_TEST_SV

class apb_base_test extends uvm_test;

    `uvm_component_utils(apb_base_test)

    apb_env env;

    apb_reset_seq   reset_seq;
    apb_write_seq   write_seq;
    apb_read_seq    read_seq;
    apb_wr_rd_seq   wr_rd_seq;
    apb_illegal_addr_seq illegal_addr_seq;

    function new(string name = "apb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
        `uvm_info(get_type_name(), "Build phase completed", UVM_MEDIUM);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "============== START APB TEST ================", UVM_NONE)

        // Tạo sequence
        reset_seq = apb_reset_seq::type_id::create("reset_seq");
        write_seq = apb_write_seq::type_id::create("write_seq");
        read_seq  = apb_read_seq::type_id::create("read_seq");
        wr_rd_seq = apb_wr_rd_seq::type_id::create("wr_rd_seq");
        illegal_addr_seq = apb_illegal_addr_seq::type_id::create("illegal_addr_seq");

        // Chạy Reset trước
        reset_seq.start(env.agent.sequencer);

        // Chạy các sequence cơ bản
        repeat(5) begin
            write_seq.start(env.agent.sequencer);
            read_seq.start(env.agent.sequencer);
            wr_rd_seq.start(env.agent.sequencer);
        end

        // Chạy sequence địa chỉ bất hợp lệ
        illegal_addr_seq.start(env.agent.sequencer);

        `uvm_info(get_type_name(), "=== All sequences completed ===", UVM_NONE)

        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "APB Base Test completed", UVM_LOW);
    endfunction

endclass : apb_base_test

`endif
