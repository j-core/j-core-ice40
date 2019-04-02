#!/usr/bin/tclsh8.6
# Sample flow script for iCEcube2 ############################################# # User Configurable section #############################################
set ::env(SBT_DIR) /opt/Lattice/sbt_backend

set device iCE40UP5K-SG48
set top_module cpu_up5k
set proj_dir [pwd]
set output_dir "upd2_Implmnt"
set edif_file "upd2.edf"
set tool_options ":edifparser -y ../work/J1/jcore-j1/free42.pcf"
########################################### # Tool Interface ############################################
set sbt_root $::env(SBT_DIR)
set sbt_tcl /opt/Lattice/sbt_backend/tcl/sbt_backend_synpl.tcl
source $sbt_tcl
run_sbt_backend_auto $device $top_module $proj_dir $output_dir $tool_options $edif_file
exit
