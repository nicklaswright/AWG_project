# AWG controller for Qubit stimulation
This repo contains the VHDL-modules I designed for an Arbitrary Waveform Generator (AWG) providing stimuli to a single Qubit. 
The IQ-mixer and UART module are omitted since they were implemented by other group members.
The implementation was done on the Zynq Ultrascale+RF SoC board.

All VHDL source files are in the folder named "src". The folder named "scripts" are just bash scripts for running Questa/Modelsim from VS Code.
The "host" folder contains the MATLAB scripts used in the lab from the host computer to control the AWG on the FPGA board.
