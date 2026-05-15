//==============================================================================
// File          : apb_monitor.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Monitor definition
//                 - Observe bus, packaging data --> transaction 
//                  --> send to Scoreboard to check 
//                      
//
// Version       : 1.0
// Date          : 13-May-2026
//==============================================================================
`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    // Virtual interface 
    virtual apb_if vif ;
    
    // Declare Analysis Port to send data to SB & Coverage 
    uvm_analysis_port #(apb_transaction) mon_ap;

    // Contructor
    function new(string name = "apb_monitor", uvm_component parent = null ); 
        super.new(name, parent);
    endfunction 

    //-------------- BUILD PHASE ---------------------

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if(!uvm_config_db#(virtual apb_if.monitor)::get(this,"","vif",vif))
            `uvm_fatal("MON","Couldn't get APB interface from config DB")
    endfunction

    //-------------- RUN PHASE ------------------------

  virtual task run_phase(uvm_phase phase);
    // Chờ reset xong
    wait(vif.presetn == 1);
    `uvm_info(get_type_name(), "Monitor started after reset", UVM_MEDIUM)

    forever begin
        collect_transaction();     // Đổi tên cho rõ
    end
endtask
    //--------------COLLECT TRANSACTION TASK -----------
   virtual task collect_transaction();
    apb_transaction trans;
    bit transaction_started = 0;

    forever begin
        // Chờ Setup Phase bắt đầu (PSEL=1, PENABLE=0)
        do begin
            @(vif.mon_cb);
        end while (!(vif.mon_cb.psel == 1 && vif.mon_cb.penable == 0));

        trans = apb_transaction::type_id::create("trans");

        // Sample Setup Phase
        trans.paddr  = vif.mon_cb.paddr;
        trans.pwrite = vif.mon_cb.pwrite;
        if (trans.pwrite)
            trans.pwdata = vif.mon_cb.pwdata;

        `uvm_info(get_type_name(), $sformatf("Detected transaction: ADDR=0x%8h WRITE=%b", trans.paddr, trans.pwrite), UVM_HIGH)

        // Chờ transaction hoàn thành (PENABLE + PREADY)
        do begin
            @(vif.mon_cb);
        end while (!(vif.mon_cb.penable == 1 && vif.mon_cb.pready == 1));

        // Sample kết quả
        trans.prdata  = vif.mon_cb.prdata;
        trans.pslverr = vif.mon_cb.pslverr;

        `uvm_info(get_type_name(), $sformatf("Collected: %s", trans.convert2string()), UVM_MEDIUM)

        // Gửi cho Scoreboard
        mon_ap.write(trans);

        // Chờ PSEL xuống thấp (kết thúc transaction)
        do begin
            @(vif.mon_cb);
        end while (vif.mon_cb.psel == 1);
    end
endtask
endclass

`endif 