onerror resume
wave tags  sim
wave update off
wave zoom range 0 49752
wave group top -backgroundcolor #004466
wave add -group top top.WB_ADDR_WIDTH -tag sim -radix hexadecimal
wave add -group top top.WB_DATA_WIDTH -tag sim -radix hexadecimal
wave add -group top top.NUM_I2C_BUSSES -tag sim -radix hexadecimal
wave add -group top top.clk -tag sim -radix hexadecimal
wave add -group top top.rst -tag sim -radix hexadecimal
wave add -group top top.cyc -tag sim -radix hexadecimal
wave add -group top top.stb -tag sim -radix hexadecimal
wave add -group top top.we -tag sim -radix hexadecimal
wave add -group top top.ack -tag sim -radix hexadecimal
wave add -group top top.adr -tag sim -radix hexadecimal
wave add -group top top.dat_wr_o -tag sim -radix hexadecimal
wave add -group top top.dat_rd_i -tag sim -radix hexadecimal
wave add -group top top.irq -tag sim -radix hexadecimal
wave add -group top {top.scl[0]} -tag sim -radix hexadecimal
wave add -group top {top.sda[0]} -tag sim -radix hexadecimal
wave insertion [expr [wave index insertpoint] + 1]
wave group top.DUT -backgroundcolor #004466
wave add -group top.DUT top.DUT.g_bus_num -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_clk[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_0[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_1[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_2[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_3[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_4[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_5[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_6[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_7[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_8[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_9[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_a[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_b[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_c[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_d[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_e[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.g_f_scl_f[63:0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.clk_i -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.rst_i -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.cyc_i -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.stb_i -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.ack_o -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.adr_i -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.we_i -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.dat_i -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.dat_o -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.irq -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.scl_i[0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.sda_i[0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.scl_o[0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT {top.DUT.sda_o[0]} -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.wr -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.rd -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.idata -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.odata -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.busy -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.captured -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.bus_id -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.bit_state -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.byte_state -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.disable -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.mcmd_wr -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.mcmd_id -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.mcmd_data -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.mrsp_wr -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.mrsp_id -tag sim -radix hexadecimal -select
wave add -group top.DUT top.DUT.mrsp_data -tag sim -radix hexadecimal -select
wave insertion [expr [wave index insertpoint] + 1]
wave update on
wave top 29
