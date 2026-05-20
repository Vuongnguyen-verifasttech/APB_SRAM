//==============================================================================
// File          : apb_env.sv
//==============================================================================
`ifndef APB_ENV_SV
`define APB_ENV_SV

class apb_env extends uvm_env; 

    `uvm_component_utils(apb_env)

    apb_agent       agent;
    apb_scoreboard  scoreboard;
    apb_coverage    cov; 

    function new(string name = "apb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        agent      = apb_agent::type_id::create("agent", this);
        scoreboard = apb_scoreboard::type_id::create("scoreboard", this);
        cov        = apb_coverage::type_id::create("cov", this);

        `uvm_info(get_type_name(), "Build phase completed", UVM_MEDIUM)
    endfunction 

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    
        agent.mon_ap.connect(scoreboard.mon_imp);
        agent.mon_ap.connect(cov.analysis_export);

        `uvm_info(get_type_name(), "Connect phase completed - Monitor connected to Scoreboard & Coverage", UVM_LOW)
    endfunction 

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "Environment report phase completed", UVM_LOW)
    endfunction 

endclass: apb_env
`endif
