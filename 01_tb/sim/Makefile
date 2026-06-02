# ==============================================================================
# Makefile APB UVM - Questasim 10.6b (Nâng Cấp Quét Regression List + Coverage)
# ==============================================================================

TOP_MODULE   = tb_top
FILELIST     = filelist.f

# Coverage Settings cho 10.6b
COV_COMPILE  = -cover bcesf
COV_SIM      = -coverage
COV_MERGE_DIR= cov_merge
COV_REPORT   = coverage_report

# ==============================================================================
# CẤU HÌNH DANH SÁCH CÁC TESTCASE MUỐN QUÉT REGRESSION
# ==============================================================================
# Mặc định khi gõ 'make run_regression' hoặc 'make all' sẽ chạy danh sách này
TEST_LIST   ?= apb_write_test \
               apb_read_test \
               apb_wr_rd_test \
               apb_reset_test \
               apb_illegal_addr_test \
               apb_stress_test \
               apb_b2b_test

# Số lượng seeds mặc định cho mỗi testcase khi chạy regression
NUM_SEEDS    ?= 3

# Tên testcase mặc định khi chạy đơn lẻ (lệnh: make sim)
TEST_NAME    ?= apb_write_test

# Chuỗi target chạy tự động toàn bộ quy trình từ Clean -> Report
all: clean init compile run_regression merge_coverage report

# Khởi tạo thư viện
init:
	vlib work
	vmap work work

# Biên dịch mã nguồn kèm cờ capture coverage
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

# ------------------------------------------------------------------------------
# Chạy 1 simulation đơn lẻ (Dùng để debug nhanh hoặc chạy chỉ 1 test cụ thể)
# Ví dụ: make sim TEST_NAME=apb_stress_test
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Chạy 1 simulation đơn lẻ: Show log trực tiếp ra Terminal + Vẫn lưu vào file
# ------------------------------------------------------------------------------
sim:
	@mkdir -p single_run_logs
	vsim -c $(COV_SIM) \
		$(TOP_MODULE) \
		+UVM_TESTNAME=$(TEST_NAME) \
		-do "run -all; coverage save -onexit $(TEST_NAME).ucdb; quit -f" \
		| tee single_run_logs/$(TEST_NAME).log

# ------------------------------------------------------------------------------
# TARGET REGRESSION CHUYÊN NGHIỆP: Vòng lặp lồng lặp (Quét Testlist x Quét Seeds)
# ------------------------------------------------------------------------------
run_regression:
	@echo "======================================================"
	@echo "=== STARTING REGRESSION: $(NUM_SEEDS) SEEDS PER TEST ==="
	@echo "======================================================"
	@mkdir -p regression_logs $(COV_MERGE_DIR)
	@for test in $(TEST_LIST); do \
		echo "----------------------------------------------------"; \
		echo " 🚀 Running Testcase: $$test"; \
		echo "----------------------------------------------------"; \
		for i in $$(seq 1 $(NUM_SEEDS)); do \
			echo "   → Seed $$i ..."; \
			vsim -c $(COV_SIM) \
				$(TOP_MODULE) \
				+UVM_TESTNAME=$$test \
				+UVM_SEED=$$i \
				-do "coverage save -onexit $(COV_MERGE_DIR)/$${test}_seed$$i.ucdb; run -all; quit -f" \
				> regression_logs/$${test}_seed$$i.log 2>&1; \
		done; \
	done
	@echo "======================================================"
	@echo "===         REGRESSION RUNS COMPLETED              ==="
	@echo "======================================================"

# Gộp tất cả các file UCDB của từng test/seed thành một file duy nhất
merge_coverage:
	@echo "=== Merging Coverage ==="
	@rm -f $(COV_MERGE_DIR)/merged.ucdb
	@if ls $(COV_MERGE_DIR)/*.ucdb >/dev/null 2>&1; then \
		vcover merge -out $(COV_MERGE_DIR)/merged.ucdb $(COV_MERGE_DIR)/*.ucdb; \
		echo "Merge completed successfully! Created: $(COV_MERGE_DIR)/merged.ucdb"; \
	else \
		echo "ERROR: No .ucdb files found in $(COV_MERGE_DIR)/! Run regression first."; \
		exit 1; \
	fi

# Xuất báo cáo chi tiết (HTML Report + Summary Text)
report:
	@echo "=== Generating HTML Coverage Report ==="
	vcover report -html -htmldir $(COV_REPORT) -verbose $(COV_MERGE_DIR)/merged.ucdb
	@echo "=== Generating Summary Text Report ==="
	vcover report -details $(COV_MERGE_DIR)/merged.ucdb > summary.txt
	@echo "Report generation finished. Check directory: $(COV_REPORT)/"

# Dọn dẹp môi trường sạch sẽ trước khi chạy lượt mới
clean:
	@echo "=== Cleaning environment ==="
	rm -rf work vsim.wlf transcript
	rm -rf regression_logs single_run_logs
	rm -rf $(COV_MERGE_DIR) $(COV_REPORT) summary.txt
	rm -f *.ucdb

.PHONY: all init compile sim run_regression merge_coverage report clean