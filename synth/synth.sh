#!/bin/sh

if [ -z "$1" ]
then
	echo Useage: $0 "<project>.prj"
	exit 1;
fi

echo Synthesis for Project $1:

LD_LIBRARY_PATH=/opt/Lattice/sbt_backend/bin/linux/opt/synpwrap:$LD_LIBRARY_PATH SYNPLIFY_PATH=/opt/Lattice/synpbase SBT_DIR=/opt/Lattice/sbt_backend/ /opt/Lattice/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj $1
