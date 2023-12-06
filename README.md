# Software that runs on DZOS

This is a repository of programs I develop (or adapt in the case of MS BASIC) for my homebrew computer _dastaZ80_ running my own operating system [dzOS](https://github.com/dasta400/dzOS)

## List of programs

* **Assembly** - Programs made with Z80 Assembly
  * **helloworld.asm** - A test I did to see if _load_ and _run_ commands work. It prints the expected text.
  * **jiffyview** - Shows current values of Jiffies bytes.
  * **loadfont** - Loads a font file to be used for text output.
  * **loadscr** - Loads and displays a raw bitmap image.
  * **memdump** - shows, in hexadecimal, all the contents (bytes) of memory (RAM) locations between two addresses. After _run memdump_, the user will be asked to enter the start and end addresses. Entering a blank address will terminate the program.
  * **mlmonitor** - Machine Language Monitor.
    * Right now it allows to:
      * Execute from a specified memory address.
      * Fill a range of locations with a specified byte.
      * Display memory as a hexadecimal dump (same as _memdump_).
      * Modify a single memory address (_poke_) with a specified value.
      * Display the value (_peek_) from a memory address.
      * Transfer segments of memory from one memory area to another.
      * Enter hexadecimal values to consecutive addresses from a start address.
    * Future features planned:
      * Assemble a line of assembly code into memory.
      * Disassemble a memory area from machine code into assembly language.
      * Load data from disk into memory.
      * Modify a single video memory address (_vpoke_) with a specified value.
      * Display the value (_vpeek_) from a video memory address.
      * Display video memory (_vmemdump_) as a hexadecimal dump.
      * Save the contents of memory onto disk.
  * **msbasic.asm** - This is the MS BASIC 7.4b NASCOM 32 KB version that Grant Searle published in his [Grant's 7-chip Z80 computer](http://searle.x10host.com/z80/SimpleZ80.html) webpage, with my own modifications to make it run in [dzOS](https://github.com/dasta400/dzOS).
  * **psgtest** - A program to test the sound output of the AY-3-8912.
  * **testjoys** - A small tool I wrote to test the Dual Joystick Port. Moving or pressing the fire buttons on any of the two joysticks shows a message on the screen telling what was pressed.
  * **vdpraster** - A test of VDP Interrupts on the VDP screen.
  * **vdpsetmode** - A test of changing VDP screen modes.
  * **vdpsprite** - A test showing a sprite on the VDP screen.
  * **vdptext** - A test showing text on the VDP screen.
  * **vramdump** - Shows, in hexadecimal, all the contents (bytes) of video memory (VRAM) locations between two addresses. After _run vramdump_, the user will be asked to enter the start and end addresses. Entering a blank address will terminate the program.
  * **pastefile** - It allows to transfer files into the dastaZ80 memory, by copying bytes typed with the keyboard, and storing them in a specified RAM address. It's very handy for testing new software under development without having to extract the MicroSD card. It's loaded into a higher RAM address (0xC420) to not use the memory space that will be used by the programs pasted. Usually programs load at $4420.
* **C** - Programs made with [Small Device C Compiler (SDCC)](http://sdcc.sourceforge.net/)
  * **crt0.s** - Sets the vector address to the start of dastaZ80 free RAM (0x4420), and makes the exit() to jump back to dastaZ80 CLI.
  * **putchar.s** - Used by _printf_, calls F_BIOS_SERIAL_CONOUT_A.
  * **helloworldSDCC.c** - It prints the expected text.

## How to make programs for DZOS (with Z80 Assembly)

Start by creating a copy of [_template.asm](https://github.com/dasta400/dzSoftware/blob/main/src/_template.asm), which already has some code on it.

If you want to use [dzOS](https://github.com/dasta400/dzOS)' _BIOS_ and/or _Kernel_ subroutines, you will need a copy of _dzOS.exp_ and _equates.inc_ from the [dzOS](https://github.com/dasta400/dzOS) repository, or like I do, just clone that repository and create soft links with _ln -s_

The _dzOS.exp_ file contains the export that TASM (_The Telemark Assembler_) creates of the subroutines and values marked as _.EXPORT_. This way you can call the subroutines from your program, because TASM will know the addresses were they are stored.

The _equates.inc_ contains all definitions for port mappings, ANSI colour numbers, and special keys like CR, SPACE, ESC.

If you want/need to have access to the _System Variables_ (SYSVARS) in RAM, get also _sysvars.exp_ from the [dzOS](https://github.com/dasta400/dzOS) repository.

Write your code under the area that says _; YOUR PROGRAM GOES HERE_.

Once finished, use [assemble.sh](https://github.com/dasta400/dzSoftware/blob/main/assemble.sh) to assemble your program with TASM.

Finally, you can take the _.bin_ and add it to a Disk Image File on the SD card. See instructions here on [How to use the SD Card module](https://github.com/dasta400/dzOS#how-to-use-the-sd-card-module).

## What is the other included code?

This could be understood as the header of executable binaries. The first instruction (*.ORG $4420*) makes the program start at that address, which is the first byte of the free RAM in the dastaZ80. You can use any address from $4420 to the end of RAM ($FFFF), but writing below $4420 will have bad consequences. From $0000 to $3FFF is where [dzOS](https://github.com/dasta400/dzOS) resides in RAM, and from $4000 to $441F is where the buffers and system variables are stored. Overwritting certain variables will make the OS crash, destroy information in the CompactFlash or behave erratically. For more information on what is exactly stored there, refer to the [Memory Map documentation](https://github.com/dasta400/dzOS/blob/master/docs/dastaZ80%20Memory%20Map.ods).

The second instruction (_jp $4425_) is a jump to address $4425. You'll understand why this is needed in a moment.

The third instruction (_.BYTE $20, $44_) is just putting a value into the current memory address. This value is the so called _load address_ and [dzOS](https://github.com/dasta400/dzOS) uses it to know where in RAM to load your program. As this will be assembled into address $4423 (because the previous _jp_ is 3 bytes long) and occupies 2 bytes, the next instruction (which is where your program starts) will be $4425. Now hopefully you understand why the _jp $4425_.

The fourth instruction (_.ORG $4425_) is actually not needed, for what I just explained, but I added it for clarity.

And finally, one **very important** instruction (_jp cli_promptloop_) that **MUST** be at the end of your code, or whenever you want to exit your program. This instruction returns the control to [dzOS](https://github.com/dasta400/dzOS) Command-Line Interpreter (CLI), so that the user can continue using it. If you don't have this, your user will be forced to reset the computer, which is not so nice.

## How to make programs for DZOS (with C)

[Small Device C Compiler (SDCC)](http://sdcc.sourceforge.net/) is a retargettable, optimizing standard C compiler that targets a different architectures, among them the Z80.

The steps on how to compile can be seen in the included [compileSDCC.sh](https://github.com/dasta400/dzSoftware/tree/main/SDCC/compileSDCC.sh) file. In summary, you write your C program and link it with two provided files (_crt0.s_ and _putchar.s_) that have been adapted to dastaZ80.
