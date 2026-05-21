`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if.monitor vif;
    uvm_analysis_port #(apb_transaction) mon_ap;

    function new(string name = "apb_monitor", uvm_component parent = null); 
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if(!uvm_config_db#(virtual apb_if.monitor)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get APB monitor interface!")
    endfunction

    virtual task run_phase(uvm_phase phase);
        wait(vif.presetn == 1);
        `uvm_info(get_type_name(), "Monitor started after reset", UVM_MEDIUM);
        forever collect_transaction();
    endtask

    //==================================================================
    // COLLECT TRANSACTION - LOG SẠCH & CHUYÊN NGHIỆP
    //==================================================================
    virtual task collect_transaction();
        apb_transaction trans;
        int wait_cnt = 0;

        // 1. SETUP PHASE
        do begin
            @(vif.mon_cb);
        end while (!(vif.mon_cb.psel && !vif.mon_cb.penable));

        trans = apb_transaction::type_id::create("trans");

        trans.paddr  = vif.mon_cb.paddr;
        trans.pwrite = vif.mon_cb.pwrite;
        if (trans.pwrite)
            trans.pwdata = vif.mon_cb.pwdata;

        `uvm_info(get_type_name(), 
            $sformatf("Detected  | ADDR=0x%8h  WRITE=%b", trans.paddr, trans.pwrite), 
            UVM_HIGH);

        // 2. ACCESS PHASE + ĐẾM WAIT CYCLES (GIỮ NGUYÊN LOGIC CŨ CỦA BẠN)
        do begin
            @(vif.mon_cb);
        end while (!vif.mon_cb.penable);

        wait_cnt = 0;
        if (!vif.mon_cb.pready) begin
            while (!vif.mon_cb.pready) begin
                @(vif.mon_cb);
                wait_cnt++;
            end
        end
        trans.wait_cycles = wait_cnt;

        // Sample response
        trans.prdata  = vif.mon_cb.prdata;
        trans.pslverr = vif.mon_cb.pslverr;

        // 3. LOG COLLECTED - ĐÃ LÀM GỌN & CHUYÊN NGHIỆP
        `uvm_info(get_type_name(), 
            $sformatf("Collected | ADDR=0x%8h  WRITE=%b  RDATA=0x%8h  SLVERR=%b  WAIT=%0d", 
                      trans.paddr, trans.pwrite, trans.prdata, trans.pslverr, trans.wait_cycles), 
            UVM_MEDIUM);

        mon_ap.write(trans);

        // 4. End transaction
        do begin
            @(vif.mon_cb);
        end while (vif.mon_cb.psel);
    endtask

endclass : apb_monitor

`endif
