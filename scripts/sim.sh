#!/bin/bash

# Specify path to source files
src=src

# Specify path to work library
work=work

# Specify path to simulation files
sim=simulation

# Check if work library exists on specified path, create the library otherwise
if [[ ! -d $work ]]; then 
    vlib $work
    echo "Created working library in $work"
else
    echo "Working library exists in $work"
fi

# Compile specified source files into work library using VHDL 2002 standard
vcom -work $work -2002 -explicit -stats=all $sim/TB.vhdl $src/wrapper.vhdl $src/nco/package/* $src/receiver.vhdl $src/control/* $src/iq/* $src/nco/src/* $src/uart/*
# Optimization
#vopt tb +acc=rn -o tb_opt
# Simulate design units in work library using command mode
vsim -i -lib $work -do $sim/TB.do tb
# Delete output WLF-file
rm vsim.wlf