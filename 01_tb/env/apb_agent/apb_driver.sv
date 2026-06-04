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
        // Assert psel for Setup and keep penable low for one clock
        vif.drv_cb.psel    <= 1;
        vif.drv_cb.penable <= 0;
        vif.drv_cb.paddr   <= tr.paddr;
        vif.drv_cb.pwrite  <= tr.pwrite;
        if (tr.pwrite) vif.drv_cb.pwdata <= tr.pwdata;

        // Wait one clock to complete SETUP
        @(vif.drv_cb);

        // ====== 2. ACCESS PHASE ============
        // Assert penable and hold psel until pready is sampled high
     

        // Wait until slave asserts pready at a clock edge
        // Use a safe loop that samples only on the clocking block boundary
        // ACCESS
vif.drv_cb.psel    <= 1;
vif.drv_cb.penable <= 1;
while (vif.drv_cb.pready !== 1'b1) begin
    @(vif.drv_cb);
end

        // Capture response (on the same clock pready was sampled)
        if (!tr.pwrite) begin
            tr.prdata = vif.drv_cb.prdata;
        end
        tr.pslverr = vif.drv_cb.pslverr;

        // ======== 3. END TRANSACTION & TRANSITION =============
        if (!b2b_mode) begin
            // Normal mode: deassert psel and penable and give one idle clock
            vif.drv_cb.psel    <= 0;
            vif.drv_cb.penable <= 0;
            @(vif.drv_cb);
        end else begin
            // Back-to-back: keep psel asserted, lower penable only; next transaction will start setup
            vif.drv_cb.penable <= 0;
        end
    endtask
endclass 

`endif