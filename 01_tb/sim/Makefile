# =============================================
# Makefile APB UVM - Questasim 10.6b (Regression + Coverage)
# =============================================

TOP_MODULE   = tb_top
FILELIST     = filelist.f

# Coverage Settings cho 10.6b
COV_COMPILE  = -cover bcesf
COV_SIM      = -coverage
COV_MERGE_DIR= cov_merge
COV_REPORT   = coverage_report

NUM_SEEDS    ?= 3
TEST_NAME    ?= apb_base_test

all: clean init compile run_regression merge_coverage report

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
		+incdir+../dut \
		$(COV_COMPILE) \
		-f $(FILELIST)

# Single simulation
sim:
	vsim -c $(COV_SIM) \
		$(TOP_MODULE) \
		+UVM_TESTNAME=$(TEST_NAME) \
		-do "run -all; coverage save $(TEST_NAME).ucdb -onexit; quit -f"

# Regression
# Regression
run_regression:
	@echo "=== Running Regression $(NUM_SEEDS) seeds ==="
	@mkdir -p regression_logs $(COV_MERGE_DIR)
	@for i in $$(seq 1 $(NUM_SEEDS)); do \
		echo "→ Seed $$i ..."; \
		vsim -c $(COV_SIM) \
			$(TOP_MODULE) \
			+UVM_TESTNAME=$(TEST_NAME) \
			+UVM_SEED=$$i \
			-do "coverage save -onexit $(COV_MERGE_DIR)/$(TEST_NAME)_seed$$i.ucdb; run -all; quit -f" \
			> regression_logs/$(TEST_NAME)_seed$$i.log 2>&1; \
	done

merge_coverage:
	@echo "=== Merging Coverage ==="
	@rm -f $(COV_MERGE_DIR)/merged.ucdb
	@if ls $(COV_MERGE_DIR)/*.ucdb >/dev/null 2>&1; then \
		vcover merge -out $(COV_MERGE_DIR)/merged.ucdb $(COV_MERGE_DIR)/*.ucdb; \
		echo "Merge completed!"; \
	else \
		echo "ERROR: No .ucdb files found! Run regression first."; \
	fi

report:
	@echo "=== Generating Report ==="
	mkdir -p $(COV_REPORT)
	vcover report -details -html -out $(COV_REPORT) $(COV_MERGE_DIR)/merged.ucdb
	vcover report -details -txt $(COV_MERGE_DIR)/merged.ucdb > $(COV_REPORT)/summary.txt
	@echo "✅ Report: ./$(COV_REPORT)/index.html"

clean:
	rm -rf work transcript vsim.wlf modelsim.ini *.log *.vcd *.fsdb \
	       regression_logs $(COV_MERGE_DIR) $(COV_REPORT) *.ucdb
	@echo "=== Clean completed! ==="

run: clean init compile sim
debug: clean init compile gui

gui:
	vsim -voptargs="+acc" $(TOP_MODULE) -do "add wave -r /*; run -all"