//==============================================================================
// File          : apb_monitor.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Monitor definition
//                 - Captures APB bus activity and sends transactions to Scoreboard
// Version       : 1.2
// Date          : 22-May-2026
//==============================================================================

`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    // Virtual interface lấy mẫu tín hiệu (Sampling)
    virtual apb_if.monitor vif;
    
    // Analysis port để xuất dữ liệu thu thập ra ngoài Scoreboard
    uvm_analysis_port #(apb_transaction) mon_ap;

    function new(string name = "apb_monitor", uvm_component parent = null); 
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if(!uvm_config_db#(virtual apb_if.monitor)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "Could not get APB monitor interface!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Chờ hệ thống ổn định sau khi nhả reset
        wait(vif.presetn == 1);
        `uvm_info(get_type_name(), "Monitor started capturing after reset", UVM_MEDIUM);
        
        // Chạy liên tục song song suốt quá trình mô phỏng
        forever begin
            collect_transaction();
        end
    endtask

    //==================================================================
    // COLLECT TRANSACTION - Thu thập thông tin chuẩn xác trên Bus
    //==================================================================
    virtual task collect_transaction();
        apb_transaction trans;
        int wait_cnt = 0;

        // ------ 1. DETECT SETUP PHASE ------
        // Chờ điều kiện bắt đầu một transaction: psel tích cực và penable chưa lên
        while (!(vif.mon_cb.psel && !vif.mon_cb.penable)) begin
            @(vif.mon_cb);
        end

        // Khởi tạo đối tượng transaction mới để lưu trữ dữ liệu thu được
        trans = apb_transaction::type_id::create("trans");
        trans.paddr  = vif.mon_cb.paddr;
        trans.pwrite = vif.mon_cb.pwrite;
        
        if (trans.pwrite) begin
            trans.pwdata = vif.mon_cb.pwdata;
        end

        `uvm_info(get_type_name(), 
            $sformatf("Detected  | ADDR=0x%8h  WRITE=%b", trans.paddr, trans.pwrite), 
            UVM_HIGH);

        // ------ 2. CAPTURE ACCESS PHASE & WAIT STATES ------
        // Chờ tín hiệu dịch pha sang Access Phase (penable = 1)
        while (!vif.mon_cb.penable) begin
            @(vif.mon_cb);
        end

        // Kiểm tra và đếm các chu kỳ đợi (Wait states) nếu Slave kéo pready = 0
        wait_cnt = 0;
        while (!vif.mon_cb.pready) begin
            wait_cnt++;
            @(vif.mon_cb);
        end
        trans.wait_cycles = wait_cnt-1;

        // Ngay tại chu kỳ mà pready = 1, tiến hành lấy mẫu kết quả trả về từ Slave
        trans.prdata  = vif.mon_cb.prdata;
        trans.pslverr = vif.mon_cb.pslverr;

        `uvm_info(get_type_name(), 
            $sformatf("Collected | ADDR=0x%8h  WRITE=%b  RDATA=0x%8h  SLVERR=%b  WAIT=%0d", 
                      trans.paddr, trans.pwrite, trans.pwrite ? 32'hxxxxxxxx : trans.prdata, trans.pslverr, trans.wait_cycles), 
            UVM_MEDIUM);
            
        // Đẩy gói tin đã thu thập đầy đủ sang cho Scoreboard kiểm tra chéo
        mon_ap.write(trans);

        // ------ 3. END TRANSACTION (Đã sửa lỗi kẹt pha B2B) ------
        // Chỉ chờ đúng 1 clock cycle kết thúc giao dịch hiện tại để giải phóng Monitor,
        // quay trở về đầu task sẵn sàng bắt ngay pha Setup của chu kỳ kế tiếp.
        @(vif.mon_cb);
    endtask
endclass 

`endif
