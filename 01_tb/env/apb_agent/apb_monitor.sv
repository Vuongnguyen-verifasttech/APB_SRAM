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
        if(!uvm_config_db#(virtual apb_if)::get(this,"","vif",vif))
            `uvm_fatal("MON","Couldn't get APB interface from config DB")
    endfunction

    //-------------- RUN PHASE ------------------------

    virtual task run_phase (uvm_phase phase);
        forever begin 
            if(!vif.presetn)
            continue;
            collect_transaction();
        end
    endtask 

    //--------------COLLECT TRANSACTION TASK -----------
    virtual task collect_transaction();
        apb_transaction tr; 

        // Wait until set up phase start
        wait(vif.mon_cb.psel == 1 && vif.mon_cb.penable == 0); 
        tr = apb_transaction::type_id::create("tr");

        // sample data in set up phase
        @(vif.pclk);
        tr.paddr = vif.mon_cb.paddr;
        tr.pwrite = vif.mon_cb.pwrite
        if(tr.pwrite) tr.pwdata = vif.mon_cb.pwdata; 

        /*
        // wait until AccESs phase end to collect data 
        wait(vif.mon_cb_penable == 1 && 
            vif.mon_cb_pready == 1);
        */
        // Khong dung wait vi kh syn theo clock , co the trigger ngay giua delta cycle --> de race condition

        do begin
            @(vif.mon_cb);
        end
        while(!(vif.mon_cb.penable &&
            vif.mon_cb.pready));

        // Sampling output
        if (!tr.pwrite) tr.prdata = vif.mon_cb.prdata;
        tr.pslverr = vif.mon_cb.pslverr; 

        `uvm_info(get_type_name(), $sformatf("Monitored: %s", tr.convert2string()), UVM_MEDIUM)

        // Send transaction to SB 
        mon_ap.write(tr);
        
        // Wait transaction end

        wait(vif.mon_cb.psel == 0);
    endtask 
endclass

`endif 