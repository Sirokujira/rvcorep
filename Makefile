##############################################################################################
## RVCore (RISC-V Core Processor) vXXXX-XX-XXx        since  2018-08-07  ArchLab. TokyoTech ##
##############################################################################################
# Verilog HDL simulator
SIM = iverilog
#SIM = verilator

# General
TOPSOURCE    = top.v
OTHERSOURCE  = main.v uart.v debug.v
OTHERSOURCE += proc.v
#OTHERSOURCE += vexrv.v vexcore.v

FLAGS  = -DSERIAL_WCNT=2 -DNO_IP

ifdef BENCH
	FLAGS += -DMEMFILE=\"${BENCH}\" -DMEM_SIZE=1024*32 -DNO_SERIAL -DPROGRESS
endif
ifdef EMBENCH
	FLAGS += -DMEMFILE=\"${EMBENCH}\" -DMEM_SIZE=1024*64 -DNO_SERIAL -DPROGRESS
endif
ifdef TEST
	FLAGS += -DMEMFILE=\"${TEST}\" -DMEM_SIZE=1024*4 -DNO_SERIAL
endif

ifdef verify
	FLAGS += -DVERIFY -DTR_BEGIN=${BEGIN} -DTR_END=${END} -DTR_FIN=${FIN}
endif
ifdef pipe
	FLAGS += -DPIPELINE
endif

ifdef simple
	FLAGS += -DD_SIMPLE_ALU -DD_SIMPLE_DMOUT -DD_SIMPLE_BTB
endif
ifdef optif
	FLAGS += -DD_SIMPLE_ALU -DD_SIMPLE_DMOUT
endif
ifdef optalu
	FLAGS += -DD_SIMPLE_BTB
endif

ifeq (${SIM},iverilog)
	FLAGS += -o simv
endif
ifeq (${SIM},verilator)
	FLAGS += --public --top-module top --clk CLK
	FLAGS += --x-assign 0 --x-initial 0
	FLAGS += --no-threads -O2
	FLAGS += -Wno-WIDTH -Wno-UNSIGNED
	FLAGS += --exe sim.cpp --cc
endif

.PHONY: all vex clean allclean run result
###############################################################################
all: rvcore

rvcore:
	${SIM} ${FLAGS} ${TOPSOURCE} ${OTHERSOURCE}
ifeq (${SIM},verilator)
	make -j -C obj_dir -f Vtop.mk Vtop
	cp obj_dir/Vtop simv
endif

vex:
	${SIM} -DVEXRV ${FLAGS} ${TOPSOURCE} ${OTHERSOURCE}
ifeq (${SIM},verilator)
	make -j -C obj_dir -f Vtop.mk Vtop
	cp obj_dir/Vtop simv
endif

###############################################################################
pipe:
	make pipe=1
vpipe:
	make vex pipe=1

###############################################################################
clean:
	rm -rf obj_dir
	rm -f simv
	rm -f verify.txt trace.txt diff.txt
allclean:
	make clean
	rm -rf main.cache main.hw main.runs main.sim main.ip_user_files
resultclean:
	rm -f result/*.txt

###############################################################################
run: simv
	./simv

###############################################################################
# benchd  : NUMBER_OF_RUNS=500
# benchd2 : NUMBER_OF_RUNS=2000
# benchd3 : NUMBER_OF_RUNS=10000
###############################################################################
benchd:
	make BENCH="bench/dhrystone.mem"
benchd2:
	make BENCH="bench/dhrystone2.mem"
benchd3:
	make BENCH="bench/dhrystone3.mem"
vbenchd:
	make vex BENCH="bench/dhrystone.mem"
vbenchd2:
	make vex BENCH="bench/dhrystone2.mem"
vbenchd3:
	make vex BENCH="bench/dhrystone3.mem"

###############################################################################
# benchc  : ITERATIONS=1
# benchc2 : ITERATIONS=2
# benchc3 : ITERATIONS=10
###############################################################################
benchc:
	make BENCH="bench/coremark.mem"
benchc2:
	make BENCH="bench/coremark2.mem"
benchc3:
	make BENCH="bench/coremark3.mem"
vbenchc:
	make vex BENCH="bench/coremark.mem"
vbenchc2:
	make vex BENCH="bench/coremark2.mem"
vbenchc3:
	make vex BENCH="bench/coremark3.mem"

###############################################################################
# embench
###############################################################################
aha-mont64:
	make EMBENCH="embench/aha-mont64.mem"
crc32:
	make EMBENCH="embench/crc32.mem"
cubic:
	make EMBENCH="embench/cubic.mem"
edn:
	make EMBENCH="embench/edn.mem"
huffbench:
	make EMBENCH="embench/huffbench.mem"
matmult-int:
	make EMBENCH="embench/matmult-int.mem"
minver:
	make EMBENCH="embench/minver.mem"
nbody:
	make EMBENCH="embench/nbody.mem"
nettle-aes:
	make EMBENCH="embench/nettle-aes.mem"
nettle-sha256:
	make EMBENCH="embench/nettle-sha256.mem"
nsichneu:
	make EMBENCH="embench/nsichneu.mem"
picojpeg:
	make EMBENCH="embench/picojpeg.mem"
qrduino:
	make EMBENCH="embench/qrduino.mem"
sglib-combined:
	make EMBENCH="embench/sglib-combined.mem"
slre:
	make EMBENCH="embench/slre.mem"
statemate:
	make EMBENCH="embench/statemate.mem"
st:
	make EMBENCH="embench/st.mem"
ud:
	make EMBENCH="embench/ud.mem"
wikisort:
	make EMBENCH="embench/wikisort.mem"
vaha-mont64:
	make vex EMBENCH="embench/aha-mont64.mem"
vcrc32:
	make vex EMBENCH="embench/crc32.mem"
vcubic:
	make vex EMBENCH="embench/cubic.mem"
vedn:
	make vex EMBENCH="embench/edn.mem"
vhuffbench:
	make vex EMBENCH="embench/huffbench.mem"
vmatmult-int:
	make vex EMBENCH="embench/matmult-int.mem"
vminver:
	make vex EMBENCH="embench/minver.mem"
vnbody:
	make vex EMBENCH="embench/nbody.mem"
vnettle-aes:
	make vex EMBENCH="embench/nettle-aes.mem"
vnettle-sha256:
	make vex EMBENCH="embench/nettle-sha256.mem"
vnsichneu:
	make vex EMBENCH="embench/nsichneu.mem"
vpicojpeg:
	make vex EMBENCH="embench/picojpeg.mem"
vqrduino:
	make vex EMBENCH="embench/qrduino.mem"
vsglib-combined:
	make vex EMBENCH="embench/sglib-combined.mem"
vslre:
	make vex EMBENCH="embench/slre.mem"
vstatemate:
	make vex EMBENCH="embench/statemate.mem"
vst:
	make vex EMBENCH="embench/st.mem"
vud:
	make vex EMBENCH="embench/ud.mem"
vwikisort:
	make vex EMBENCH="embench/wikisort.mem"

###############################################################################
wc:
	wc -l *.v *.vh

###############################################################################
# verify
#VFILE = "bench/coremark"
VFILE = "embench/aha-mont64"
BEGIN = 0
END   = 1000000
FIN   = 1000001

trace:
	simrv -a -m ${VFILE}.bin -t ${BEGIN} ${END} -e ${FIN}
verify:
#	make verify=1 BENCH="${VFILE}.mem"
	make verify=1 EMBENCH="${VFILE}.mem"
	make run
diff:
	make clean
	make trace
	make verify
	diff -ur trace.txt verify.txt > diff.txt
#	diff -yr --width=160 trace.txt verify.txt > diff.txt

###############################################################################
vexnum = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16

result:
	make resultd2
	make resultc2
	make resultdc2
	make resultdc3

resultd2:
	make clean
	echo "Performance Result" > result/resultd2.txt
	echo "RVCoreP" >> result/resultd2.txt
	make benchd2
	make run >> result/resultd2.txt
	make clean
	for i in ${vexnum}; do\
		echo "VexRiscv_config$${i}" >> result/resultd2.txt;\
		cp vexriscv/VexRiscv_config$${i}.v vexcore.v;\
		make vbenchd2;\
		make run >> result/resultd2.txt;\
		make clean;\
	done
	cp vexriscv/VexRiscv_config8.v vexcore.v
resultc2:
	make clean
	echo "Performance Result" > result/resultc2.txt
	echo "RVCoreP" >> result/resultc2.txt
	make benchc2
	make run >> result/resultc2.txt
	make clean
	for i in ${vexnum}; do\
		echo "VexRiscv_config$${i}" >> result/resultc2.txt;\
		cp vexriscv/VexRiscv_config$${i}.v vexcore.v;\
		make vbenchc2;\
		make run >> result/resultc2.txt;\
		make clean;\
	done
	cp vexriscv/VexRiscv_config8.v vexcore.v

resultdc2:
	make clean
	echo "Performance Result" > result/resultdc2.txt
	cp vexriscv/VexRiscv_config8.v vexcore.v
	echo "VexRiscv_config8 : Dhrystone" >> result/resultdc2.txt
	make vbenchd2
	make run >> result/resultdc2.txt
	make clean
	echo "VexRiscv_config8 : Coremark" >> result/resultdc2.txt
	make vbenchc2
	make run >> result/resultdc2.txt
	make clean
	cp vexriscv/VexRiscv_config16.v vexcore.v
	echo "VexRiscv_config16 : Dhrystone" >> result/resultdc2.txt
	make vbenchd2
	make run >> result/resultdc2.txt
	make clean
	echo "VexRiscv_config16 : Coremark" >> result/resultdc2.txt
	make vbenchc2
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-simple : Dhrystone" >> result/resultdc2.txt
	make benchd2 simple=1
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-simple : Coremark" >> result/resultdc2.txt
	make benchc2 simple=1
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-optALU : Dhrystone" >> result/resultdc2.txt
	make benchd2 optalu=1
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-optALU : Coremark" >> result/resultdc2.txt
	make benchc2 optalu=1
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-optIF : Dhrystone" >> result/resultdc2.txt
	make benchd2 optif=1
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-optIF : Coremark" >> result/resultdc2.txt
	make benchc2 optif=1
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-optALL : Dhrystone" >> result/resultdc2.txt
	make benchd2
	make run >> result/resultdc2.txt
	make clean
	echo "RVCoreP-optALL : Coremark" >> result/resultdc2.txt
	make benchc2
	make run >> result/resultdc2.txt
	make clean
	cp vexriscv/VexRiscv_config8.v vexcore.v
resultdc3:
	make clean
	echo "Performance Result" > result/resultdc3.txt
	cp vexriscv/VexRiscv_config8.v vexcore.v
	echo "VexRiscv_config8 : Dhrystone" >> result/resultdc3.txt
	make vbenchd3
	make run >> result/resultdc3.txt
	make clean
	echo "VexRiscv_config8 : Coremark" >> result/resultdc3.txt
	make vbenchc3
	make run >> result/resultdc3.txt
	make clean
	cp vexriscv/VexRiscv_config16.v vexcore.v
	echo "VexRiscv_config16 : Dhrystone" >> result/resultdc3.txt
	make vbenchd3
	make run >> result/resultdc3.txt
	make clean
	echo "VexRiscv_config16 : Coremark" >> result/resultdc3.txt
	make vbenchc3
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-simple : Dhrystone" >> result/resultdc3.txt
	make benchd3 simple=1
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-simple : Coremark" >> result/resultdc3.txt
	make benchc3 simple=1
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-optALU : Dhrystone" >> result/resultdc3.txt
	make benchd3 optalu=1
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-optALU : Coremark" >> result/resultdc3.txt
	make benchc3 optalu=1
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-optIF : Dhrystone" >> result/resultdc3.txt
	make benchd3 optif=1
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-optIF : Coremark" >> result/resultdc3.txt
	make benchc3 optif=1
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-optALL : Dhrystone" >> result/resultdc3.txt
	make benchd3
	make run >> result/resultdc3.txt
	make clean
	echo "RVCoreP-optALL : Coremark" >> result/resultdc3.txt
	make benchc3
	make run >> result/resultdc3.txt
	make clean
	cp vexriscv/VexRiscv_config8.v vexcore.v

benchmark = aha-mont64 crc32 cubic edn huffbench matmult-int minver nbody nettle-aes nettle-sha256 nsichneu picojpeg qrduino sglib-combined slre st statemate ud wikisort

resultem:
	make clean
	echo "Performance Result" > result/resultem.txt
	echo "RVCoreP" >> result/resultem.txt
	for bench in ${benchmark}; do\
		echo $${bench};\
		make $${bench};\
		make run >> result/resultem.txt;\
		make clean;\
	done
	cp vexriscv/VexRiscv_config8.v vexcore.v
	echo "VexRiscv_config8" >> result/resultem.txt
	for bench in ${benchmark}; do\
		echo vex8-$${bench};\
		make v$${bench};\
		make run >> result/resultem.txt;\
		make clean;\
	done
	cp vexriscv/VexRiscv_config16.v vexcore.v
	echo "VexRiscv_config16" >> result/resultem.txt
	for bench in ${benchmark}; do\
		echo vex16-$${bench};\
		make v$${bench};\
		make run >> result/resultem.txt;\
		make clean;\
	done

###############################################################################
