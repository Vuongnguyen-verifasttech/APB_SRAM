//==============================================================================
// File          : apb_transaction.sv
// Author        : [vnguyen]
// Company       : [Verifast]
// Project       : APB Verification Environment
// Description   : APB Transaction definition
//                 - Defines the structure and behavior of APB transactions
//                 - Data packet that need to be tested               
//
// Version       : 1.0
// Date          : 12-May-2026
//==============================================================================

`ifndef APB_TRANSACTION_SV
`define APB_TRANSACTION_SV

class apb_transaction extends uvm_sequence_item;
    `uvm_object_utils(apb_transaction)

    // APB transaction fields
    rand bit [31:0] paddr;
    rand bit [31:0] pwdata;
    rand bit pwrite; // 1: write, 0: read
    rand int wait_cycles; 
    
    // Monitor fields :được sử dụng để lưu trữ kết quả phản hồi từ thiết kế (DUT) sau khi một giao dịch kết thúc.
    bit [31:0] prdata;
    bit pslverr;
    bit sucess; // Transaction success flag

// ======== Constraint ============================
    constraint addr_alignment {
        paddr[1:0] == 2'b00; // constraint addr must be 4 byte aligned
    }
    constraint wait_range {
        wait_cycles inside {[0:10]};
    }
    // DUT chỉ co mem_depth = 10 --> 1024 word --> address range là 0x0000_0000 đến 0x0000_0fff de kich hoat bao loi pslverr
    constraint addr_range {
        paddr inside {[32'h0000_0000:32'h0000_0fff]} 
    }

// ======== Constructor ============================
    function new(string name = "apb_transaction");
        super.new(name);
    endfunction 

//=========Debugging support =========================
    virtual function string convert2string();
        string s;
        s =$sformatf("ADDR= 0x%8h WRITE= %b DATA= 0x%8h WAIT= %0d SLVERR= %b RDATA= 0x%8h",
                        paddr, pwrite, pwdata, wait_cycles, pslverr, prdata);
        return s;
    endfunction

//function to print okela when use uvm_info
    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("ADDR", paddr, 32 , UVM_HEX);
        printer.print_field("WRITE", pwrite, 1, UVM_BIN);
        printer.print_field("DATA", pwrite?pwdata:prdata , 32, UVM_HEX);
        printer.print_field("WAIT", wait_cycles, 8, UVM_DEC);
        printer.print_field("SLVERR", pslverr, 1, UVM_BIN);
    endfunction
endclass: apb_transaction

`endif