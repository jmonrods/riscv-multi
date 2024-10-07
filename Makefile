# ./multi/: multi-cycle riscv cpu
cpu_multi: clean
	vlib work
	vmap work work
	vlog -sv ./multi/cpu_tb.sv ./multi/cpu.sv
	vsim -c work.cpu_tb -do "run -all; quit -f;"

# clean: removes output files
clean:
	rm ./vsim.wlf -f
	rm ./vsim.dbg -f
	rm ./modelsim.ini -f
	rm ./coverage.ucdb -f
	rm ./coverage.txt -f
	rm ./work/ -rf
	rm ./transcript -f