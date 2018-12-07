#!/bin/sh 
# usage: asm.sh kernelName ASM_ARGS
# example: asm.sh kernelName -mcpu=gfx900
f=$1
shift
ASM=/opt/rocm/bin/hcc
${ASM} -x assembler -target amdgcn--amdhsa $@ -c -o $f.o $f.s
${ASM} -target amdgcn--amdhsa $f.o -o $f.co
