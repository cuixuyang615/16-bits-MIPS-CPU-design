Copyright CUIXUYANG

-------------------------------------Design Description----------------------------------------
This is a classic 16bits MIPS CPU design, which is done by Verilog and simulated with ModelSim.
Before simulation, you can directly write your code in assembly format and then transfer it
to machine code with python code 'MIPS.py'. 

Note that the paradigm of 16bits MIPS is in the 'instruction set.txt', and you are supposed 
to write your assembly code in 'instruction.txt',whose result will be saved in 'test.txt'.
The default path of these 2 files are 'D:/' , however, you can change it in python code 
according to your thought.

---------------------------------------File Description--------------------------------------------
.\example			A running example done by author, which includes the waveform result, 
			test assembly code and machine code

.\example	\instruction.txt	You can write your assembly code here

.\example	\test.txt		The visual memory file that will be loaded into visual ram in MIPS_tb.v, which
			is usually writen by 'MIPS.py', however, you can also write it yourself.

.\instruction set.txt		The paradigm of this MIPS CPU instruction set

.\MIPS.py			A python code that transfer your assembly code to machine code, and the
			default starting address will be 0x0 (set in the MIPS_tb.v).

.\MIPS.v			The top design done with Verilog

.\MIPS_tb.v		The simulation file done with Verilog
