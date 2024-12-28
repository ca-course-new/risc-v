# risc-v

This repo contains the design files of
## a soft processor implementing RISC-V RV32I with Verilog HDL: rv32i_modelsim
The components of the processor are implemented with individual Verilog HDL files. The top-level Verlog HDL file is rv32i_cpu.v. The processor is a 5-stage pipeline with fowarding and hazard detection units. For convenience of simulation in ModelSim/Questa, the design modules of register file and memory are merged into the top-level file. Register contents can be monitored with either their index number (genregs[0]-genregs[31]), or their names in RISC-V calling convention (ra, gp, a0-a7, etc). Memory contents are relayed to the output of the WB stage and can be monitored with mirror_mem signal. Other important internal signals, such as pc, instruction and ALU result, are relayed similarly as debug_pc, debug_ins and debug_res. In a typical simulation in ModelSim/Questa, users monitor signals such as clk, rst, debug_pc, debug_ins, debug_res, and any interested register and memory units.

A testbench block is embedded in rv32i_cpu.v as well. The simulated clock is 50 Mhz (20ns period) and the first 40 ns is set for reset. Therefore, the first instruction's result should be visible between 130 ns and 150 ns after the simulation begins. Refer to online tutorials on how to compile and simulate in ModelSim/Questa.  
## a soft processor synthesizable in Intel Quartus Prime: rv32i_quartus
This is a Quartus Prime project implementing and synthesizing the above RV32I soft processor. The targeted FPGA is EP4CE15E22C7N. The top-level file is RV32I.bdf, which contains the 5-stage pipeline, and driving modules for peripheral devices such as TFT LCD, SDRAM, ESP-01S (Wi-Fi).
## a Python-based assembler: rv32i_assembler.py
To compile a user assembly program, use the command:
python rv32i_assembler.py userprogram.asm
, which will generate rv32i_machine.hex. To simulate the execution in ModelSim, copy the hex file into the soft processor's ModelSim project folder. To run it on a soft processor synthesized in Quartus Prime, copy the hex file into the soft processor's Quartus project folder. 
## an custom FPGA evaluation board
The schematics and PCB layout files are included as PDFs.
## example RISC-V assembly programs to run on the soft processor
1. hex_calculator.asm: a hexadecimal calculator supporting addition and subtraction.
2. sdram.asm: a demo program to test read, write and auto-refresh of the SDRAM on the FPGA evaluation board. The DISPREG procedure can display the content of any register in 8-digit hexadecimal format. The DISP procedure can display any visible ASCII character. These procedures can be directly used by students in projects that require displaying on the TFT LCD.
3. wifi.asm: a demo program to test the Wi-Fi module ESP-01S on the FPGA evaluation board.
