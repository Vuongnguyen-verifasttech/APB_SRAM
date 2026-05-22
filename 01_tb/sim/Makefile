# ==============================================================================
# File          : Makefile
# Project       : APB Verification Environment
# Description   : Quy trình chuẩn hóa Simulation & Regression theo Gold File
# ==============================================================================

TOP_MODULE       = work.hdl_top
PKG_FILE         = ../include/apb_pkg.sv
TB_FILE          = ../tb/tb_top.sv
FILELIST         = filelist.f
UVM_VERBOSITY    = UVM_MEDIUM

# Cấu hình mặc định cho chạy đơn lẻ (Single run)
TEST             = apb_base_test
SEED             = 1
TEST_FOLDER      = $(TEST)_seed_$(SEED)

# Cấu hình cho chạy hàng loạt (Regression)
REGRESSION_SEEDS = 10
REG_TEST_NAME    = apb_base_test

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
		-f $(FILELIST) \
		$(PKG_FILE) \
		$(TB_FILE)

# ==============================================================================
# SIMULATION SINGLE SEED (Debug nhanh 1 cấu hình)
# ==============================================================================
sim:
	rm -rf $(TEST_FOLDER)
	mkdir -p $(TEST_FOLDER)
	vsim -vopt \
		$(TOP_MODULE) \
		-voptargs=+acc=npr \
		-assertdebug \
		+UVM_PHASE_TRACE \
		+UVM_OBJECTION_TRACE \
		+UVM_TESTNAME=$(TEST) \
		+UVM_SEED=$(SEED) \
		+UVM_VERBOSITY=$(UVM_VERBOSITY) \
		-l $(TEST_FOLDER)/$(TEST).log \
		-sva \
		-coverage \
		-c -solvefaildebug \
		-do "log -r /*; add wave -r /*; coverage save -onexit -assert -directive -cvg -codeAll $(TEST_FOLDER)/$(TEST)_coverage.ucdb; run -all; exit" \
		-wlf $(TEST_FOLDER)/waveform.wlf
	
	# Xuất báo cáo HTML riêng cho test này
	vcover report -html $(TEST_FOLDER)/$(TEST)_coverage.ucdb -htmldir $(TEST_FOLDER)/html_cov_report -details
	@echo "--- Single simulation completed! Log: $(TEST_FOLDER)/$(TEST).log ---"

# ==============================================================================
# REGRESSION SETUP (Chạy tự động chuỗi nhiều seed và tự động gộp)
# ==============================================================================
regression:
	@echo "=== Starting APB UVM Regression with $(REGRESSION_SEEDS) seeds ==="
	@for i in $$(seq 1 $(REGRESSION_SEEDS)); do \
		echo "Running $(REG_TEST_NAME) with Seed $$i ..."; \
		mkdir -p $(REG_TEST_NAME)_seed_$$i; \
		vsim -vopt $(TOP_MODULE) \
			-voptargs=+acc=npr \
			-assertdebug \
			+UVM_TESTNAME=$(REG_TEST_NAME) \
			+UVM_SEED=$$i \
			+UVM_VERBOSITY=$(UVM_VERBOSITY) \
			-l $(REG_TEST_NAME)_seed_$$i/$(REG_TEST_NAME).log \
			-sva -coverage -c -solvefaildebug \
			-do "coverage save -onexit -assert -directive -cvg -codeAll $(REG_TEST_NAME)_seed_$$i/$(REG_TEST_NAME)_coverage.ucdb; run -all; exit" \
			-wlf $(REG_TEST_NAME)_seed_$$i/waveform.wlf > /dev/null 2>&1; \
	done
	@echo "=== All seeds executed. Starting merge process... ==="
	make merge_cov_report

# ==============================================================================
# MERGE COVERAGE (Quét sạch các folder con để gộp database)
# ==============================================================================
merge_cov_report:
	rm -rf merged_coverage.ucdb merged_cov_html_report
	@echo "Merging all .ucdb files found in subdirectories..."
	
	# Sử dụng cấu trúc quét "-64 */*.ucdb" chuẩn từ file mẫu của bạn
	vcover merge merged_coverage.ucdb -64 */*.ucdb  
	
	# Kết xuất báo cáo HTML tổng thể
	vcover report -html merged_coverage.ucdb -htmldir ./merged_cov_html_report -details
	
	@echo "";
	@echo "-----------------------------------------------------------------";
	@echo " SUCCESS: Coverage report merged successfully!";
	@echo " To view report: firefox merged_cov_html_report/index.html &";
	@echo "-----------------------------------------------------------------";
	@echo "";

# ==============================================================================
# CLEANUP (Dọn sạch chuẩn không ảnh hưởng tới code gốc)
# ==============================================================================
clean_simulate:
	rm -rf *_seed_*
	rm -rf merged_coverage.ucdb merged_cov_html_report

clean_compile:
	rm -rf work/ transcript vsim.wlf

clean: clean_compile clean_simulate
	@echo "Simulation directory is fully cleaned."