#!/bin/sh

rm *.o *.cf  

ghdl -a cpu2j0_pkg.vhd components_pkg.vhd mult_pkg.vhd decode_pkg.vhd decode_body.vhd datapath_pkg.vhd cpu.vhd decode.vhd decode_core.vhd decode_table.vhd datapath.vhd register_file_sync.vhd mult.vhd 

#ghdl -a decode_table_reverse.vhd
ghdl -a decode_table_rom.vhd

ghdl -a  data_bus_pkg.vhd monitor_pkg.vhd ram_init.vhd lattice_ebr.vhd lattice_spr.vhd bus_monitor.vhd timeout_cnt.vhd cpu_simple_sram.vhd cpu_bulk_sram.vhd

ghdl -a --work=sb_ice40_components_syn clk_sim.vhd

ghdl -a ../disp_drv/disp_drv_pkg.vhd ../disp_drv/disp_drv.vhd

ghdl -a cpu_up5k_42s.vhd up5k_tb.vhd

ghdl -e up5k_tb

./up5k_tb --stop-time=3000ns --wave=out.ghw --ieee-asserts=disable-at-0  --activity=all > /dev/null
./up5k_tb --stop-time=2ms --ieee-asserts=disable-at-0
