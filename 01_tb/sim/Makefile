# =============================================
# Makefile cho APB UVM - Questasim 10.6b
# =============================================

TOP_MODULE   = tb_top
PKG_FILE     = ../include/apb_pkg.sv
TB_FILE      = ../tb/tb_top.sv
FILELIST     = filelist.f

# Coverage cho Questa 10.6b
COV_COMPILE  = -cover bcesf
COV_SIM      = -coverage
COV_MERGE_DIR= cov_merge
COV_REPORT   = coverage_report

NUM_SEEDS    ?= 5
TEST_NAME    ?= apb_base_test

all: clean init compile run_regression merge_coverage report

init:
	vlib work
	vmap work work

compile:
	vlog -work work -sv -mfcu -timescale 1ns/1ps +acc \
		+incdir+../interface \
		+incdir+../include \
		+incdir+../env/apb_agent \
		+incdir+../seq \
		+incdir+../test \
		+incdir+../dut \
		$(COV_COMPILE) \
		-f $(FILELIST) \
		$(PKG_FILE) \
		$(TB_FILE)

sim:
	vsim -c $(COV_SIM) \
		$(TOP_MODULE) \
		+UVM_TESTNAME=$(TEST_NAME) \
		-do "run -all; coverage save $(TEST_NAME).ucdb -onexit; quit -f"

run_regression:
	@echo "=== Starting Regression with $(NUM_SEEDS) seeds ==="
	@mkdir -p regression_logs $(COV_MERGE_DIR)
	@for i in $$(seq 1 $(NUM_SEEDS)); do \
		echo "→ Running seed $$i ..."; \
		vsim -c $(COV_SIM) \
			$(TOP_MODULE) \
			+UVM_TESTNAME=$(TEST_NAME) \
			+UVM_SEED=$$i \
			-do "run -all; coverage save $(COV_MERGE_DIR)/$(TEST_NAME)_seed$$i.ucdb -onexit; quit -f" \
			> regression_logs/$(TEST_NAME)_seed$$i.log 2>&1 || echo "Seed $$i failed!"; \
	done
	@echo "=== Regression completed! ==="

merge_coverage:
	@echo "=== Merging Coverage ==="
	@rm -f $(COV_MERGE_DIR)/merged.ucdb
	vcover merge -out $(COV_MERGE_DIR)/merged.ucdb $(COV_MERGE_DIR)/*.ucdb

report:
	@echo "=== Generating Coverage Report ==="
	mkdir -p $(COV_REPORT)
	vcover report -details -html -out $(COV_REPORT) $(COV_MERGE_DIR)/merged.ucdb
	vcover report -details -txt $(COV_MERGE_DIR)/merged.ucdb > $(COV_REPORT)/summary.txt
	@echo "Report ready: ./$(COV_REPORT)/index.html"

run: clean init compile sim

gui:
	vsim -voptargs="+acc" $(TOP_MODULE) -do "add wave -r /*; run -all"

clean:
	rm -rf work transcript vsim.wlf modelsim.ini *.log *.vcd *.fsdb \
	       regression_logs $(COV_MERGE_DIR) $(COV_REPORT) *.ucdb
	@echo "=== Clean completed! ==="

help:
	@echo "make all                  --> Full regression + coverage"
	@echo "NUM_SEEDS=10 make all     --> Chạy nhiều seeds"