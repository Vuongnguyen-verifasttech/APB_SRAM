# =============================================
# Makefile cho APB UVM Testbench - Questasim
# =============================================

# --- Khai báo biến ---
TOP_MODULE   = tb_top
TB_FILE      = tb/tb_top.sv
FILELIST     = 00_src/filelist.f
PKG_FILE     = include/apb_pkg.sv

# --- Lệnh mặc định ---
all: clean init compile sim

# --- 1. Tạo thư viện ---
init:
	vlib work
	vmap work work

# --- 2. Biên dịch ---
compile:
	vlog -work work -sv -mfcu -timescale 1ns/1ps \
		+acc \
		+incdir+interface \
		+incdir+env/apb_agent \
		+incdir+seq \
		+incdir+test \
		+incdir+include \
		+UVM_TESTNAME=apb_base_test \
		-f $(FILELIST) \
		$(PKG_FILE) \
		$(TB_FILE)

# --- 3a. Chạy simulation không GUI (console) ---
sim:
	vsim -c $(TOP_MODULE) \
		-do "run -all; quit -f"

# --- 3b. Chạy với GUI ---
gui:
	vsim -voptargs="+acc" $(TOP_MODULE) \
		-do "add wave -r /*; run -all"

# --- 4. Dọn dẹp ---
clean:
	rm -rf work transcript vsim.wlf modelsim.ini *.vcd *.fsdb *.log
	@echo "Clean completed!"

# --- 5. Chạy full flow ---
run: clean init compile sim

# --- 6. Debug mode ---
debug:
	vsim -voptargs="+acc" $(TOP_MODULE) \
		-do "add wave -r /*; run -all"