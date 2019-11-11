#!/bin/sh

# Compile+simulate j1 processor for ICE 40 using https://github.com/ghdl/ghdl

# clean files from last build (if any)
rm -f *.o *.cf *.ghw

# Convert VHDL source into Abstract Syntax Tree in database
echo Analyze...

# General CPU plumbing, not architecture specific
ghdl -a cpu2j0_pkg.vhd components_pkg.vhd mult_pkg.vhd decode_pkg.vhd decode_body.vhd datapath_pkg.vhd cpu.vhd decode.vhd decode_core.vhd decode_table.vhd datapath.vhd register_file_sync.vhd mult.vhd 

# Using the "staircase" version of the instruction decoder. The 2 other
# versions started life as generated code from the same microcode spreadsheet,
# are here for historical reasons and regression testing.
#ghdl -a decode_table_reverse.vhd
#ghdl -a decode_table_rom.vhd
ghdl -a decode_table_simple.vhd

# ICE40 FPGA macro block simulations and SOC plumbing
ghdl -a  data_bus_pkg.vhd monitor_pkg.vhd ram_init.vhd lattice_ebr.vhd bus_monitor.vhd timeout_cnt.vhd cpu_simple_sram.vhd
ghdl -a --work=sb_ice40_components_syn clk_sim.vhd
ghdl -a cpu_lattice.vhd lattice_tb.vhd

# Done loading source into database. Now optimize & convert AST into a netlist.
echo Elaborate...
ghdl -e lattice_tb

# the ghdl "mcode" version is a bytecode interpreter / jit run via ghdl -r,
# the llvm backend creates standalone binaries runnable as ./lattice_tb
# it's otherwise the same command line arguments

echo Create waveforms
# Run briefly creating waveform outputs for use by gtkwave
# (this is very slow, so we only do a little of it)
ghdl -r lattice_tb --stop-time=3000ns --wave=out.ghw --ieee-asserts=disable-at-0  --activity=all > /dev/null

# Run longer test (faster, no waveforms) allowing CPU test to complete.
# Produces debug output from the LED driver (lattice_tb.vhd has debug
# printfs that only work in the simulator, optimized out on real hardware).
echo Run test ROM in processor simulation
ghdl -r lattice_tb --stop-time=1ms --ieee-asserts=disable-at-0
