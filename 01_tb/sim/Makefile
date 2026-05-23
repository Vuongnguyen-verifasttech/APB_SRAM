# =============================================
# Makefile cho APB UVM - Questasim (Regression + Coverage)
# =============================================

TOP_MODULE   = tb_top
PKG_FILE     = ../include/apb_pkg.sv
TB_FILE      = ../tb/tb_top.sv
FILELIST     = filelist.f

# ====================== COVERAGE SETTINGS ======================
COV_OPTS     = -coverage -coveropt 3 +cover=cbesf
COV_MERGE_DIR= cov_merge
COV_REPORT   = coverage_report

# ====================== REGRESSION SETTINGS ======================
NUM_SEEDS    ?= 5                    # Số lần chạy với seed random
TEST_NAME    ?= apb_base_test        # Default test

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
		+incdir+../coverage \
		-f $(FILELIST) \
		$(PKG_FILE) \
		$(TB_FILE)

# ====================== SINGLE RUN ======================
sim:
	vsim -c $(COV_OPTS) \
		$(TOP_MODULE) \
		+UVM_TESTNAME=$(TEST_NAME) \
		-do "run -all; coverage save $(TEST_NAME).ucdb; quit -f"

# ====================== REGRESSION ======================
run_regression:
	@echo "=== Starting Regression with $(NUM_SEEDS) seeds ==="
	@mkdir -p regression_logs $(COV_MERGE_DIR)
	@for i in $$(seq 1 $(NUM_SEEDS)); do \
		echo "Running seed $$i ..."; \
		vsim -c $(COV_OPTS) \
			$(TOP_MODULE) \
			+UVM_TESTNAME=$(TEST_NAME) \
			+UVM_SEED=$$i \
			-do "run -all; coverage save $(COV_MERGE_DIR)/$(TEST_NAME)_seed$$i.ucdb; quit -f" \
			> regression_logs/$(TEST_NAME)_seed$$i.log 2>&1; \
	done
	@echo "=== Regression completed! ==="

# ====================== MERGE COVERAGE ======================
merge_coverage:
	@echo "=== Merging Coverage Databases ==="
	@rm -f $(COV_MERGE_DIR)/merged.ucdb
	vcover merge -stats -out $(COV_MERGE_DIR)/merged.ucdb $(COV_MERGE_DIR)/*.ucdb
	@echo "=== Coverage merged successfully ==="

# ====================== COVERAGE REPORT ======================
report:
	@echo "=== Generating Coverage Report ==="
	vcover report -details -html -out $(COV_REPORT) $(COV_MERGE_DIR)/merged.ucdb
	vcover report -details -txt $(COV_MERGE_DIR)/merged.ucdb > $(COV_REPORT)/summary.txt
	@echo "=== Coverage report generated at ./$(COV_REPORT)/ ==="

# ====================== UTILITY ======================
run: clean init compile sim

gui:
	vsim -voptargs="+acc" $(TOP_MODULE) -do "add wave -r /*; run -all"

clean:
	rm -rf work transcript vsim.wlf modelsim.ini *.log *.vcd *.fsdb \
	       regression_logs $(COV_MERGE_DIR) $(COV_REPORT) *.ucdb
	@echo "=== Clean completed! ==="

debug: clean init compile gui

# ====================== HELP ======================
help:
	@echo "Available targets:"
	@echo "  make run_regression     - Chạy regression với nhiều seed"
	@echo "  make merge_coverage     - Merge tất cả .ucdb"
	@echo "  make report             - Tạo HTML + TXT coverage report"
	@echo "  make all                - Full flow: compile + regression + merge + report"
	@echo "  NUM_SEEDS=10 make all   - Chạy với 10 seeds"