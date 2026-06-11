export ECE745_PROJECT_HOME ?= $(PWD)/../../..
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

clean:
	rm -rf work *.wlf transcript qrun.out *.ucdb

comp_I2C_MB:
	vcom ../rtl/iicmb_int_pkg.vhd
	vcom ../rtl/iicmb_pkg.vhd
	vcom +cover=bcesf ../rtl/mbyte.vhd
	vcom +cover=bcesf ../rtl/mbit.vhd
	vcom +cover=bcesf ../rtl/bus_state.vhd
	vcom +cover=bcesf ../rtl/filter.vhd
	vcom +cover=bcesf ../rtl/conditioner.vhd
	vcom +cover=bcesf ../rtl/conditioner_mux.vhd
	vcom +cover=bcesf ../rtl/iicmb_m.vhd
	vcom +cover=bcesf ../rtl/regblock.vhd
	vcom +cover=bcesf ../rtl/wishbone.vhd
	vcom +cover=bcesf ../rtl/iicmb_m_wb.vhd

comp_bench: comp_ncsu_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg
	vlog +cover=bcesf ../testbench/top.sv

optimize:
	vopt +acc +cover=bcesf top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

# For converting .xml test plan to .ucdb file [cite: 55]
convert:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./test_plan.ucdb

# Merges test_plan.ucdb and merged_tests.ucdb into regression.ucdb [cite: 56]
merge:
	vcover merge regression.ucdb test_plan.ucdb merged_tests.ucdb

# Opens GUI for viewing regression.ucdb [cite: 57]
view:
	vsim -viewcov ./regression.ucdb
