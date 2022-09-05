# Software that runs on DZOS

This is a repository of programs I develop (or adapt in the case of MS BASIC) for my homebrew computer *dastaZ80* running my own operating system [DZOS](https://github.com/dasta400/dzOS)

## List of programs

* **Assembly** - Programs made with Z80 Assembly
  * **helloworld.asm** - A test I did to see if *load* and *run* commands work. It prints the expected text.
  * **bas32K.asm** - This is the MS BASIC 7.4b NASCOM 32 KB version of Grant Searle published in his [Grant's 7-chip Z80 computer](http://searle.x10host.com/z80/SimpleZ80.html) webpage, with a very tiny adaptation to make it run in DZOS. Please notice that this version, as offered by Grant Searle, doesn't allow to load or save files. You'll have to type the programs manually and it will be lost once you switch the computer.
* **C** - Programs made with [Small Device C Compiler (SDCC)](http://sdcc.sourceforge.net/)
  * **crt0.s** - Sets the vector address to the start of dastaZ80 free RAM (0x4420), and makes the exit() to jump back to dastaZ80 CLI.
  * **putchar.s** - Used by *printf*, calls F_BIOS_SERIAL_CONOUT_A.
  * **helloworldSDCC.c** - It prints the expected text.

## How to make programs for DZOS (with Z80 Assembly)

Start by creating a copy of *_template.asm*, which already has some code on it.

If you want to use DZOS' *BIOS* and/or *Kernel* subroutines, you will need a copy of *BIOS.exp*, *CLI.exp* and *equates.inc* from the [DZOS](https://github.com/dasta400/dzOS) repository, or like I do, just clone that repository and create soft links with *ln -s*

The *.exp* files contain the export that TASM (*The Telemark Assembler*) creates of the subroutines marked as *.EXPORT*. This way you can call the subroutines from your program, because TASM will know the addresses were they are stored.

The *equates.inc* contains all definitions for port mappings, ANSI colour numbers, and special keys like CR, SPACE, ESC.

If you want/need to have access to the *System Variables* (SYSVARS) in RAM, get also *sysvars.asm* from the [DZOS](https://github.com/dasta400/dzOS) repository.

Write your code under the area that says *; YOUR PROGRAM GOES HERE*.

Once finished, use *assemble.sh* to assemble your program with TASM.

Finally, you can take the *.bin* and add it to the CompactFlash card. At the moment this process is very unfriendly. Read below for detailed instructions.

## What is the other included code?

This could be understood as the header of executable binaries. The first instruction (*.ORG $4420*) makes the program start at that address, which is the first byte of the free RAM in the dastaZ80. You can use any address from $4420 to the end of RAM ($FFFF), but writing below $4420 will have bad consequences. From $0000 to $3FFF is where DZOS resides in RAM, and from $4000 to $441F is where the buffers and system variables are stored. Overwritting certain variables will make the OS crash, destroy information in the CompactFlash or behave erratically. For more information on what is exactly stored there, refer to the [Memory Map documentation](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20Memory%20Map.ods).

The second instruction (*jp $4425*) is a jump to address $4425. You'll understand why this is needed in a moment.

The third instruction (*.BYTE $20, $44*) is just putting a value into the current memory address. This value is the so called *load address* and DZOS uses it to know where in RAM to load your program. As this will be assembled into address $4423 (because the previous *jp* is 3 bytes long) and occupies 2 bytes, the next instruction (which is where your program starts) will be $4425. Now hopefully you understand why the *jp $4425*.

The fourth instruction (*.ORG $4425*) is actually not needed, for what I just explained, but I added it for clarity.

And finally, one **very important** instruction (*jp cli_promptloop*) that **__MUST__** be at the end of your code, or whenever you want to exit your program. This instruction returns the control to DZOS Command-Line Interpreter (CLI), so that the user can continue using it. If you don't have this, your user will be forced to reset the computer, which is not so nice.

## How to make programs for DZOS (with C)

Small Device C Compiler (SDCC) is a retargettable, optimizing standard C compiler that targets a different architectures, among them the Z80.

The steps on how to compile can be seen in the included [compileSDCC.sh](https://github.com/dasta400/dzSoftware/tree/main/SDCC/compileSDCC.sh) file. In summary, you write your C program and link it with two provided files (*crt0.s* and *putchar.s*) that have been adapted to dastaZ80.

## How I transfer my program to the CompactFlash?

TBD