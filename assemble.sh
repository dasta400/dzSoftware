#!/bin/bash

wine TASM.EXE -80 -b -a -fFF src/$1.asm bin/$1.bin lst/$1.lst

