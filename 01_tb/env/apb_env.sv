//==============================================================================
// File          : apb_env.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB environmrnt 
//                 - Connect agent and scoreboard 
//                      
//
// Version       : 1.0
// Date          : 14-May-2026
//==============================================================================
`ifndef APB_ENV_SV
`define APB_ENV_SV

class apb_env extends uvm_env; 

    `uvm_component_utils(apb_env)

    apb_agent agent;
    apb_scoreboard scoreboard;

    function new(string name ="apb_env", uvm_component parent = null);
        super.new(name, parent);// sai thu tu giua parent va name
    endfunction 

    //=========== BUILD PHASE =========================

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Create agent 
        agent = apb_agent::type_id::create("agent", this);
        //Create Scoreboard
        scoreboard = apb_scoreboard::type_id::create("scoreboard", this);

    `uvm_info(get_type_name(),"Build phase completed", UVM_MEDIUM)

    endfunction 

    //============ CONNECT PHASE =======================

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    
        // Connect SB & Monitor 
        agent.mon_ap.connect(scoreboard.mon_imp);
        `uvm_info(get_type_name(),"Connect phase completed - Monitor connected to Scoreboard",UVM_LOW)// thieu UVM_LOW
    endfunction 

    //============= REPORT PHASE ========================

    virtual function void report_phase(uvm_phase phase); // thieu ;
        super.report_phase(phase);
        `uvm_info(get_type_name(),"Enviroment report phase completed", UVM_LOW)
    endfunction 

endclass: apb_env
`endif
