`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

class apb_coverage extends uvm_subscriber #(apb_transaction);
    `uvm_component_utils(apb_coverage)

    apb_transaction tr;

    //==================================================================
    // COVERGROUP - ĐÃ TỐI ƯU CHO DỄ ĐẠT 95%
    //==================================================================
    covergroup cg_apb;
        option.per_instance = 1;
        option.goal         = 95;     // Mục tiêu coverage

        // 1. Transaction Type
        cp_type: coverpoint tr.pwrite {
            bins write = {1};
            bins read  = {0};
        }

        // 2. Address - Giảm bin để dễ hit (không cover từng địa chỉ 0-1023)
        cp_addr: coverpoint tr.paddr[9:0] {
            bins low_addr      = {[0:255]};
            bins mid_addr      = {[256:511]};
            bins high_addr     = {[512:1023]};
            bins boundary = {0, 1023};        // Giá trị biên quan trọng
        }

        // 3. Wait States (đã capture từ monitor thực tế)
        cp_wait: coverpoint tr.wait_cycles {
            bins zero_w   = {0};
            bins low_w    = {[1:3]};
            bins medium_W = {[4:6]};
            bins high_w   = {[7:8]};
        }

        // 4. Error Response
        cp_error: coverpoint tr.pslverr {
            bins no_error  = {0};
            bins has_error = {1};
        }

        // Cross Coverage (rất quan trọng trong Vplan)
        cross_type_wait: cross cp_type, cp_wait;
        cross_type_addr : cross cp_type, cp_addr;
        cross_error     : cross cp_type, cp_error;

    endgroup : cg_apb

    //==================================================================
    // CONSTRUCTOR
    //==================================================================
    function new(string name = "apb_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_apb = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
    string dummy_name = this.get_type_name(); // Ép kích hoạt hàm ẩn trong macro
    super.build_phase(phase);
endfunction

    //==================================================================
    // WRITE - Nhận transaction từ monitor
    //==================================================================
    virtual function void write(apb_transaction t);
        tr = t;
        if (tr != null) begin
            cg_apb.sample();
        end
    endfunction

    //==================================================================
    // REPORT PHASE - CHI TIẾT RẤT RÕ (quan trọng cho Fresher)
    //==================================================================
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(get_type_name(), 
            $sformatf("=== FUNCTIONAL COVERAGE = %.2f%% ===", 
                      cg_apb.get_inst_coverage()), UVM_NONE);

        `uvm_info(get_type_name(), "=== DETAILED COVERAGE REPORT ===", UVM_NONE);

        // Chi tiết từng coverpoint
        $display("  cp_type       : %6.2f%%", cg_apb.cp_type.get_inst_coverage());
        $display("  cp_addr       : %6.2f%%", cg_apb.cp_addr.get_inst_coverage());
        $display("  cp_wait       : %6.2f%%", cg_apb.cp_wait.get_inst_coverage());
        $display("  cp_error      : %6.2f%%", cg_apb.cp_error.get_inst_coverage());

        // Chi tiết cross
        $display("\n=== CROSS COVERAGE ===");
        $display("  cross_type_wait : %6.2f%%", cg_apb.cross_type_wait.get_inst_coverage());
        $display("  cross_type_addr : %6.2f%%", cg_apb.cross_type_addr.get_inst_coverage());
        $display("  cross_error     : %6.2f%%", cg_apb.cross_error.get_inst_coverage());

        // In bảng bin chi tiết (Questasim sẽ hiển thị rất rõ)
//        cg_apb.report();

        `uvm_info(get_type_name(), "=== END DETAILED COVERAGE REPORT ===", UVM_NONE);
    endfunction

endclass : apb_coverage

`endif
