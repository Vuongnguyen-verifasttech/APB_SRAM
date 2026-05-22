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
		+incdir+../coverage \
		+UVM_TESTNAME=apb_base_test \
		-f $(FILELIST) \
		$(PKG_FILE) \
		$(TB_FILE)

sim:
	vsim -c $(TOP_MODULE) -do "run -all; quit -f"

gui:
	vsim -voptargs="+acc" $(TOP_MODULE) -do "add wave -r /*; run -all"

run: clean init compile sim

# =============================================
# REGRESSION SETUP
# =============================================

REGRESSION_SEEDS = 10          # Số seed muốn chạy
TEST_NAME = apb_base_test      # Test mặc định

# Chạy 1 lần (debug)
run:
	make clean compile sim

# Chạy Regression đầy đủ
regression:
	@echo "=== Starting APB UVM Regression with $(REGRESSION_SEEDS) seeds ==="
	@for i in $$(seq 1 $(REGRESSION_SEEDS)); do \
		echo "Running seed $$i ..."; \
		vsim -c $(TOP_MODULE) +UVM_TESTNAME=$(TEST_NAME) +UVM_SEED=$$i \
			-do "run -all; quit -f" > run_seed_$$i.log; \
		echo "Seed $$i completed. Check run_seed_$$i.log"; \
	done
	@echo "=== Regression Completed with $(REGRESSION_SEEDS) seeds ==="

# Chạy nhanh regression (5 seeds)
regression-quick:
	REGRESSION_SEEDS=5 make regression

clean:
	rm -rf work transcript vsim.wlf modelsim.ini *.log *.vcd *.fsdb
	@echo "=== Clean completed! ==="

debug: clean init compile gui
