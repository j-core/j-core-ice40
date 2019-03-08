#!/bin/sh

rm -r work sb_ice40_components_syn  

nvc -a cpu2j0_pkg.vhd components_pkg.vhd mult_pkg.vhd decode_pkg.vhd decode_body.vhd datapath_pkg.vhd cpu.vhd decode.vhd decode_core.vhd decode_table.vhd decode_table_reverse.vhd datapath.vhd register_file.vhd mult.vhd 

nvc -a  data_bus_pkg.vhd monitor_pkg.vhd ram_init.vhd lattice_ebr.vhd bus_monitor.vhd timeout_cnt.vhd cpu_simple_sram.vhd

nvc --work=sb_ice40_components_syn -a clk_sim.vhd

nvc -L . -a cpu_lattice.vhd lattice_tb.vhd

nvc -L . -e -V lattice_tb
