# ==============================================================================
# File          : Makefile
# Author        : [vnguyen]
# Company       : [Verifast]
# Project       : APB Verification Environment
# Description   : Makefile cho APB UVM - Questasim
#                 - Hỗ trợ biên dịch, mô phỏng đơn lẻ, chạy regression và merge coverage
# Version       : 1.1
# Date          : 22-May-2026
# ==============================================================================

TOP_MODULE   = tb_top
PKG_FILE     = ../include/apb_pkg.sv
TB_FILE      = ../tb/tb_top.sv
FILELIST     = filelist.f               # Đặt chung trong thư mục sim/
SEED         = 1                        # Seed mặc định cho lệnh sim đơn lẻ

all: clean init compile sim

# Khởi tạo thư mục thư viện làm việc
init:
	vlib work
	vmap work work

# Biên dịch mã nguồn với đầy đủ các thư mục include
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

# Mô phỏng đơn lẻ (Dùng để debug nhanh 1 seed)
sim:
	vsim -coverage -c $(TOP_MODULE) \
		+UVM_TESTNAME=apb_base_test \
		+UVM_SEED=$(SEED) \
		-do "run -all; coverage save -onexit coverage_seed_$(SEED).ucdb; quit -f"

# Mở giao diện đồ họa (GUI) để xem dạng sóng sóng (Waveform)
gui:
	vsim -voptargs="+acc" $(TOP_MODULE) -do "add wave -r /*; run -all"

# Dọn dẹp nhanh và chạy lại quy trình biên dịch + mô phỏng đơn lẻ
run: clean init compile sim

# ==============================================================================
# REGRESSION SETUP (ĐÃ SỬA LỖI MERGE COVERAGE)
# ==============================================================================

REGRESSION_SEEDS = 10          # Số lượng seed muốn chạy tự động khi chạy regression
TEST_NAME = apb_base_test      # Tên testcase mặc định để chạy regression

# Chạy Regression tự động nhiều seed liên tiếp
regression:
	@echo "=== Starting APB UVM Regression with $(REGRESSION_SEEDS) seeds ==="
	@for i in $$(seq 1 $(REGRESSION_SEEDS)); do \
		echo "Running seed $$i ..."; \
		vsim -coverage -c $(TOP_MODULE) +UVM_TESTNAME=$(TEST_NAME) +UVM_SEED=$$i \
			-do "run -all; coverage save -onexit coverage_seed_$$i.ucdb; quit -f" > run_seed_$$i.log; \
		echo "Seed $$i completed. Check run_seed_$$i.log"; \
	done
	@echo "=== Regression Completed with $(REGRESSION_SEEDS) seeds ==="

# Gộp (Merge) tất cả các database coverage đơn lẻ và xuất báo cáo báo cáo dạng HTML/Text
merge:
	vcover merge -out total_coverage.ucdb coverage_seed_*.ucdb
	vcover report -details -cvg -file coverage_report.txt total_coverage.ucdb
	vcover report -details -html -file cov_html total_coverage.ucdb
	@echo "===================================================================="
	@echo " Coverage merged successfully!"
	@echo " - Summary Text Report  : coverage_report.txt"
	@echo " - Detailed HTML Report : cov_html/index.html (Mở bằng trình duyệt)"
	@echo "===================================================================="

# Dọn dẹp các file rác phát sinh sau khi mô phỏng để làm sạch thư mục làm việc
clean:
	rm -rf work vsim.wlf transcript
	rm -rf *.log *.ucdb cov_html coverage_report.txt
	@echo "Cleaned simulation directory."