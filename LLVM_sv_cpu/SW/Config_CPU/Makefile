###############################################################################
#
# @author Milos Subotic <milos.subotic.sm@gmail.com>
# @license MIT
#
# @brief Makefile for Config_CPU project.
#
###############################################################################
# User defines.

ISET_DEF=config/sv_cpu.isd.jl
ISET_P=../../../FPGA/rtl/rtl__sv_cpu/common/instr_set.gen.vhd
ASM=./out/sv-asm.jl

###############################################################################
# Targets.

.PHONY: default asm clean

###############################################################################
# Private vars.

GEN_ISET=./tools/gen_instr_set.jl

###############################################################################
# Rules.

default: ${ASM}

${ISET_P} ${ASM}: ${GEN_ISET} ${ISET_DEF}
	mkdir -p out
	${GEN_ISET} --i-isd ${ISET_DEF} --o-asm ${ASM} --o-vhd ./out/instr_set.gen.vhd
	sed -i -n '/^[ ]*#=.*=#$$/!p' ${ASM}
	sed -i 's/#=.*=#//g' ${ASM}
	#cp ./out/instr_set.gen.vhd ${ISET_P}


#TODO Integrate above.
vscode:
	cp -r src/micuri.sv-asm* ~/.vscode/extensions
	rm -f ~/.vscode/extensions/extensions.json

###############################################################################
# Housekeeping.

clean:
	rm -rf out

###############################################################################
