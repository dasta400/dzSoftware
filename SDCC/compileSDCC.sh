#!/bin/bash

# I'm using SDCC and HEX2BIN that comes with CPCtelera (https://lronaldo.github.io/cpctelera/)
# because I already have it installed on my development machine

ASM=${CPCT_PATH}'/tools/sdcc-3.6.8-r9946/bin/sdasz80'
CC=${CPCT_PATH}'/tools/sdcc-3.6.8-r9946/bin/sdcc'
HEX2BIN=${CPCT_PATH}'/tools/hex2bin-2.0/bin/hex2bin'

$ASM -o src/putchar.s
$ASM -o src/crt0.s

mv src/*.rel rel/

$CC -mz80 --code-loc 0x4440 --data-loc 0 --no-std-crt0 rel/crt0.rel rel/putchar.rel src/$1.c

mv $1.ihx ihx/
mv $1.lk lk/
mv $1.lst lst/
mv $1.map map/
mv $1.noi noi/
mv $1.rel rel/
mv $1.sym sym/
mv $1.asm asm/

$HEX2BIN ihx/$1.ihx
mv ihx/$1.bin bin/