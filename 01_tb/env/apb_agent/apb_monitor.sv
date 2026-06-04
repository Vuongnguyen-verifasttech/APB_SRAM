//==============================================================================
// File          : apb_monitor.sv
// Author        : [vnguyen]
// Description   : APB Monitor
//                 - Capture APB transaction
//                 - Support wait-state
//                 - Support back-to-back transfer
//==============================================================================

`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)

    // Virtual Interface
    virtual apb_if.monitor vif;

    // Analysis Port
    uvm_analysis_port #(apb_transaction) mon_ap;

    function new(string name="apb_monitor",
                 uvm_component parent=null);
        super.new(name,parent);
    endfunction

    //=========================================================
    // BUILD
    //=========================================================
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon_ap = new("mon_ap", this);

        if(!uvm_config_db#(virtual apb_if.monitor)::get(
                this, "", "vif", vif))
        begin
            `uvm_fatal("MON",
                "Could not get APB monitor interface")
        end
    endfunction

    //=========================================================
    // RUN
    //=========================================================
    virtual task run_phase(uvm_phase phase);

        wait(vif.presetn === 1'b1);

        `uvm_info(get_type_name(),
                  "Monitor started capturing after reset",
                  UVM_MEDIUM)

        forever begin
            collect_transaction();
        end

    endtask

    //=========================================================
    // COLLECT TRANSACTION
    //=========================================================
    virtual task collect_transaction();

        apb_transaction trans;
        int wait_cnt;

        //-----------------------------------------------------
        // 1. WAIT FOR SETUP PHASE
        //-----------------------------------------------------
        do begin
            @(vif.mon_cb);
        end
        while(!(vif.mon_cb.psel &&
                !vif.mon_cb.penable));

        //-----------------------------------------------------
        // 2. CAPTURE SETUP INFORMATION
        //-----------------------------------------------------
        trans = apb_transaction::type_id::create("trans");

        trans.paddr  = vif.mon_cb.paddr;
        trans.pwrite = vif.mon_cb.pwrite;

        if(vif.mon_cb.pwrite)
            trans.pwdata = vif.mon_cb.pwdata;

        `uvm_info(get_type_name(),
            $sformatf(
                "Detected  | ADDR=0x%08h WRITE=%0b",
                trans.paddr,
                trans.pwrite
            ),
            UVM_HIGH)

        //-----------------------------------------------------
        // 3. WAIT FOR ACCESS PHASE
        //-----------------------------------------------------
        do begin
            @(vif.mon_cb);
        end
        while(!vif.mon_cb.penable);

        //-----------------------------------------------------
        // 4. COUNT WAIT STATES
        //-----------------------------------------------------
        wait_cnt = 0;

        while(vif.mon_cb.pready !== 1'b1) begin
            wait_cnt++;
            @(vif.mon_cb);
        end

        trans.wait_cycles = wait_cnt;

        //-----------------------------------------------------
        // 5. SAMPLE RESPONSE
        //-----------------------------------------------------
        if(!trans.pwrite)
            trans.prdata = vif.mon_cb.prdata;

        trans.pslverr = vif.mon_cb.pslverr;

        //-----------------------------------------------------
        // 6. REPORT
        //-----------------------------------------------------
        `uvm_info(get_type_name(),
            $sformatf(
                "Collected | ADDR=0x%08h WRITE=%0b DATA=0x%08h RDATA=0x%08h WAIT=%0d SLVERR=%0b",
                trans.paddr,
                trans.pwrite,
                trans.pwdata,
                trans.prdata,
                trans.wait_cycles,
                trans.pslverr
            ),
            UVM_MEDIUM)

        //-----------------------------------------------------
        // 7. SEND TO SCOREBOARD
        //-----------------------------------------------------
        mon_ap.write(trans);

    endtask

endclass

`endif