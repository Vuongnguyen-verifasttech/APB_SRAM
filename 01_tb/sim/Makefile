# =============================================
# Makefile cho APB UVM - Questasim
# Filelist đặt chung trong thư mục sim/
# =============================================

TOP_MODULE   = tb_top
PKG_FILE     = ../include/apb_pkg.sv
TB_FILE      = ../tb/tb_top.sv
FILELIST     = filelist.f               # ← Đặt chung thư mục sim

all: clean init compile sim

init:
	vlib work
	vmap work work

compile:
	vlog -work work -sv -mfcu -timescale 1ns/1ps +acc \
		+incdir+../interface \
		+incdir+../env/apb_agent \
		+incdir+../seq \
		+incdir+../test \
		+incdir+../include \
		+UVM_TESTNAME=apb_base_test \
		-f $(FILELIST) \
		$(PKG_FILE) \
		$(TB_FILE)

sim:
	vsim -c $(TOP_MODULE) -do "run -all; quit -f"

gui:
	vsim -voptargs="+acc" $(TOP_MODULE) -do "add wave -r /*; run -all"

run: clean init compile sim

clean:
	rm -rf work transcript vsim.wlf modelsim.ini *.log *.vcd *.fsdb
	@echo "=== Clean completed! ==="

debug: clean init compile gui
