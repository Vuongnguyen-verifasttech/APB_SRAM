//==============================================================================
// File          : apb_agent.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Monitor definition
//                 - Container contains Driver, Monitor, Sequencer  
//                      
//
// Version       : 1.0
// Date          : 13-May-2026
//==============================================================================

`ifndef APB_AGENT_SV
`define APB_AGENT_SV

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    // Child Components
    apb_driver    driver;
    apb_monitor   monitor;
    uvm_sequencer #(apb_transaction) sequencer;

    // Analysis Port để Environment kết nối tới
    uvm_analysis_port #(apb_transaction) mon_ap;

    // Constructor
    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Khởi tạo Analysis Port
        mon_ap = new("mon_ap", this);

        // Lưu ý: Không cần khai báo lại 'is_active', dùng luôn biến có sẵn của uvm_agent
        // Lấy cấu hình từ config_db, nếu không có mặc định là ACTIVE
        if(!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
            `uvm_info("AGT", "No is_active config, defaulting to UVM_ACTIVE", UVM_LOW)
        end

        // Luôn luôn có monitor
        monitor = apb_monitor::type_id::create("monitor", this);

        // Chỉ tạo Driver/Sequencer nếu là ACTIVE
        if (is_active == UVM_ACTIVE) begin 
            driver    = apb_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(apb_transaction)::type_id::create("sequencer", this);
        end
    endfunction 
    
    // Connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // 1. Kết nối Sequencer và Driver
        if (is_active == UVM_ACTIVE) begin 
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end

        // 2. Kết nối Analysis Port của Monitor ra Analysis Port của Agent
        // Giả sử trong Monitor bạn đặt tên port là 'item_collected_port'
        monitor.mon_ap.connect(this.mon_ap);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Agent Mode: %s", is_active == UVM_ACTIVE ? "ACTIVE" : "PASSIVE"), UVM_LOW)
    endfunction    

endclass
`endif