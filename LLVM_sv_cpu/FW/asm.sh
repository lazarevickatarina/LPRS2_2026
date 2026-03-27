#!/bin/bash

D="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" >/dev/null 2>&1 && pwd )"

pushd $D/Compiler/Config_CPU/
make
popd

ASM=$1
B=`basename ${ASM%%.sv.asm}`
W=`dirname ${ASM}`
HEX="$W/build/$B.sv.hex"
PROC="$W/build/$B.proc.sv.asm"
COMP=$D/Compiler/Config_CPU/out/sv-asm.jl

mkdir -p "$W/build/"
if [ $ASM -nt $HEX ] || [ $COMP -nt $HEX ]
then
	echo PROC=$PROC
	#TODO R_ω instead R_w.
	#	-H Maybe it generate right code, just warn
	#		-H Suppress warning
	clang -E -x assembler-with-cpp $ASM -o $PROC
	R=$?
	if (( $R != 0 ))
	then
		exit $R
	fi

	echo HEX=$HEX

	$COMP $PROC $HEX
	R=$?
	if (( $R != 0 ))
	then
		exit $R
	fi

	if [ "$2" = "" ]
	then
		$D/Compiler/Config_CPU/tools/objcopy.jl \
			--i-ihex $HEX \
			--o-vhd-pkg $D/../FPGA/tb/tb__cpu/machine_code.gen.vhd \
			--o-c-h $D/../FPGA/FW/test__cpu/11_exec_hardcoded/src/machine_code.gen.h
		R=$?
		if (( $R != 0 ))
		then
			exit $R
		fi
	fi
fi