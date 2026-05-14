//==============================================================================
// File          : apb_driver.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Driver definition
//                 - Handles the driving of APB transactions to the DUT
//                      
//
// Version       : 1.0
// Date          : 12-May-2026
//==============================================================================

`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV 

class apb_driver extends uvm_driver #(apb_transaction);
    `uvm_component_utils (apb_driver)
    // Virtual interface to drive signals
    virtual apb_if vif;

    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

//============= Main driving task ============================
// Build phase: get the virtual interface from the config DB
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual apb_if.driver)::get(this,"","vif", vif)) 
            `uvm_fatal("DRV", " Couldn't get APB interface from config DB")
        endfunction
//Run phase
    virtual task run_phase(uvm_phase phase);
        //Init default values for APB signals

        reset_bus();
        // Chờ cho đến khi reset kết thúc (presetn = 1)
        wait(vif.presetn === 1'b1);

        
        forever begin 
            // Get the next transaction from the sequencer
            seq_item_port.get_next_item(req);

            // Convert transaction to APB signal 
            drive_transaction(req);

            // Indicate to the sequencer that the item is done
            seq_item_port.item_done();
        end
    endtask

    // task reset bus 
    task reset_bus ();
        vif.drv_cb.psel <= 0; 
        vif.drv_cb.penable <= 0; 
        vif.drv_cb.pwrite <= 0; 
        vif.drv_cb.paddr <= 0;
        vif.drv_cb.pwdata <= 0; 
    endtask 



    // Task thuc hien APB protocol 
    task drive_transaction(apb_transaction tr);
        @(vif.drv_cb);
        //====== Set up phase =============
        vif.drv_cb.psel <= 1;
        vif.drv_cb.penable <= 0;
        vif.drv_cb.paddr <= tr.paddr; //// Đưa địa chỉ từ transaction ra bus
        vif.drv_cb.pwrite <= tr.pwrite;
        if (tr.pwrite) vif.drv_cb.pwdata <= tr.pwdata;
        @(vif.drv_cb);

        //======== Acess phase=============
        vif.drv_cb.penable <= 1; 
        // Wait until pready = 1
        while (!vif.drv_cb.pready) begin 
            @(vif.drv_cb);
        end

        // Logic cho lenh READ
        if (!tr.pwrite) tr.prdata = vif.drv_cb.prdata;
        tr.pslverr = vif.drv_cb.pslverr; 

        // End transaction 
        vif.drv_cb.psel <=0;
        vif.drv_cb.penable <= 0;
    endtask
endclass 

`endif 
 
