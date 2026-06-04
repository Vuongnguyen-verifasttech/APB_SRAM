//==============================================================================
// File          : apb_driver.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Driver definition - Fixed setup phase & pready synchronization
//                 - Handles driving APB transactions to the DUT with B2B support
// Version       : 1.3
// Date          : 22-May-2026
//==============================================================================

`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV 

class apb_driver extends uvm_driver #(apb_transaction);
    `uvm_component_utils (apb_driver)
    
    // Virtual interface to drive signals
    virtual apb_if.driver vif;
    
    // Biến cấu hình chế độ chạy gối đầu liên tục (Back-to-Back)
    bit b2b_mode = 0;

    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

    // Build phase: get the virtual interface from the config DB
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual apb_if.driver)::get(this,"","vif", vif)) begin
            `uvm_fatal("DRV", "Couldn't get APB interface from config DB")
        end
    endfunction

    // Run phase
    virtual task run_phase(uvm_phase phase);
        // Khởi tạo các tín hiệu bus về giá trị mặc định ban đầu
        reset_bus();
        
        // Chờ cho đến khi hệ thống nhả Reset (presetn tích cực mức cao)
        wait(vif.presetn === 1'b1);
        
        // 🌟 SỬA LỖI 1: Đồng bộ với cạnh Clock của Clocking Block ngay sau khi nhả reset.
        // Việc này giúp Driver không bị lệch pha bất đồng bộ ở Transaction đầu tiên.
        @(vif.drv_cb); 
        `uvm_info(get_type_name(), "Driver started after reset released and clock synchronized", UVM_MEDIUM);
        
        forever begin 
            // Lấy transaction tiếp theo từ sequencer
            seq_item_port.get_next_item(req);
            
            // Thực thi đưa dữ liệu transaction ra các đường pin vật lý của Bus
            drive_transaction(req);
            
            // Báo cáo hoàn thành item hiện tại để sequencer giải phóng
            seq_item_port.item_done();
        end
    endtask

    // Task reset bus 
    task reset_bus ();
        vif.drv_cb.psel    <= 0; 
        vif.drv_cb.penable <= 0; 
        vif.drv_cb.pwrite  <= 0; 
        vif.drv_cb.paddr   <= 0;
        vif.drv_cb.pwdata  <= 0;
    endtask 

    // Task thực hiện giao thức APB 
    task drive_transaction(apb_transaction tr);
        // ====== 1. SETUP PHASE =============
        // Kéo psel lên tích cực ngay lập tức và giữ penable = 0
        vif.drv_cb.psel    <= 1;
        vif.drv_cb.penable <= 0;
        vif.drv_cb.paddr   <= tr.paddr; // Cập nhật địa chỉ mới từ transaction
        vif.drv_cb.pwrite  <= tr.pwrite;
        
        if (tr.pwrite) begin
            vif.drv_cb.pwdata <= tr.pwdata; // Cập nhật dữ liệu ghi nếu là lệnh WRITE
        end
        
        // Chờ đúng 1 clock để kết thúc Setup Phase và chuyển dịch sang Access Phase
        @(vif.drv_cb); 

        // ======== 2. ACCESS PHASE =============
        vif.drv_cb.penable <= 1;
        
        // SỬA ĐỔI ĐỘT PHÁ: Check pready ngay chu kỳ đầu tiên mà không bị block clock bừa bãi
        forever begin
            // Nếu pready đã bằng 1 sẵn (hoặc vừa lên 1 cùng lúc với penable), kết thúc ngay tại clock tới
            if (vif.drv_cb.pready == 1'b1) begin
                break;
            end
            // Nếu chưa bằng 1, lúc này mới thực sự chờ chu kỳ tiếp theo (Wait State)
            @(vif.drv_cb);
        end

        // Thu thập dữ liệu phản hồi từ phía Slave nếu đây là lệnh READ
        if (!tr.pwrite) begin
            tr.prdata = vif.drv_cb.prdata;
        end
        tr.pslverr = vif.drv_cb.pslverr;

        // ======== 3. END TRANSACTION & TRANSITION =============
        if (!b2b_mode) begin
            // Chế độ THƯỜNG: Hạ toàn bộ tín hiệu để trả bus về trạng thái nghỉ Idle
            vif.drv_cb.psel    <= 0;
            vif.drv_cb.penable <= 0;
            @(vif.drv_cb); // Cho phép bus nghỉ tối thiểu 1 chu kỳ Idle hoàn chỉnh
        end 
        else begin 
            // Chế độ BACK-TO-BACK: Chỉ hạ penable để ngắt Transaction cũ.
            // Tuyệt đối giữ psel = 1 và KHÔNG gọi lệnh chờ clock @(vif.drv_cb).
            // Ngay chu kỳ sau, task được tái gọi sẽ đè dữ liệu mới lên bus tạo Setup Phase chuẩn.
            vif.drv_cb.penable <= 0;
        end
    endtask
endclass 

`endif