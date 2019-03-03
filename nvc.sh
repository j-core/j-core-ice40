#!/bin/sh

nvc -a cpu2j0_pkg.vhd components_pkg.vhd mult_pkg.vhd decode_pkg.vhd decode_body.vhd datapath_pkg.vhd cpu.vhd decode.vhd decode_core.vhd decode_table.vhd decode_table_reverse.vhd datapath.vhd register_file.vhd mult.vhd 

nvc -a  data_bus_pkg.vhd monitor_pkg.vhd  asymmetric_ram.vhd bus_monitor.vhd timeout_cnt.vhd cpu_sram.vhd cpu_pure_tb.vhh

nvc -e -V cpu_pure_tb
