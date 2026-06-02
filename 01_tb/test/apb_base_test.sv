`ifndef APB_BASE_TEST_SV
`define APB_BASE_TEST_SV

class apb_base_test extends uvm_test;
    `uvm_component_utils(apb_base_test)

    apb_env env;

    function new(string name = "apb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Khởi tạo môi trường env chung cho toàn bộ hệ thống test
        env = apb_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // In cấu trúc sơ đồ phân cấp cấu trúc testbench ra log file để dễ debug
        uvm_top.print_topology();
    endfunction
endclass

`endif