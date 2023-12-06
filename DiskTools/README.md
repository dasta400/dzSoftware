# Disk Image Tools for dastaZ80

This is a collection of Disk Image Tools I wrote for running on a PC.

A Disk Image is a file that contains a snapshot of a bit-by-bit copy of a
storage device's structure. In the case of the dastaZ80, this structure is
defined by the characteristics of the DZFS (dastaZ80 File System). Each image
file can be understood as a separate hard disk drive connected to the computer,
but in the form of a file instead of being a physical hard disk drive.

These Disk Images are used with the [Arduino Serial Multi-Device Controller
(ASMDC)](https://github.com/dasta400/asmdc) and with the **Serial HDD Simulator**
contained in this collection.

## Tools

### SerialHDDsimul.c (Serial HDD Simulator)

Written in C. Compile with _gcc SerialHDDsimul.c -o SerialHDDsimul_

At the back of the dastaZ80 computer there is a 6-pin header to which an 
FTDI-to-USB cable can be connected. In fact, only the pins _TX_ and _RX_ are
internally connected, so any serial TTL signal can be connected here.

The SerialHDDsimul program runs on a PC and simulates the behaviour of the SD
card attached to the [Arduino Serial Multi-Device Controller (AMDC)](https://github.com/dasta400/asmdc).

It's great for testing new software during development, as you don't need to
copy the binary to an SD card and extract/insert the SD card all the time in
your PC and then in the dastaZ80.

Also, the read/write speed is much better. ????????????

* Parameters
  * **serial_port** (e.g. _/dev/ttyUSB0_)
  * **portspeed** (e.g. 115200)
  * **dskimages_folder** (folder where the _.cfg_ and Disk Images (_.dsk_) are in your PC)

### imgmngr (Image Manager)

Written in [FreeBASIC](https://www.freebasic.net). Compile with _fbc -static imgmngr.bas_

Allows to add, extract, rename, delete and change attributes of files inside a
DZFS image file. Plus create new image file, display the image file's
catalogue and display the Superblock information.

* Parameters:
  * **-new** \<file> \<label> = create a new image
  * **-sblock**               = show Superblock
  * **-cat**                  = show disk Catalogue
  * **-add** \<file>          = add file to image
  * **-get** \<file>          = extract file from image
  * **-del** \<file>          = mark file as deleted
  * **-ren** \<old> \<new>    = rename old filename to new
  * **-attr** \<file> \<RHSE> = set new attributes to file

### makeimgfile (Make Image File)

Written in [FreeBASIC](https://www.freebasic.net). Compile with _fbc -static makeimgfile.bas_

Allows to create a Disk Image File containing files from a list, directly on the SD Card.

* Parameters:
  * \<filelist> = list of files to include in the Disk Image File.
    * Create an ASCII text file, and in each line add the name of a binary file to be added to the Disk Image File.
    * Lines starting with _#_ are ignored (i.e. commented line).
    * Always leave an empty line or with a comment (#) after the last image name.
  * \<imgfile>  = name of the Disk Image File to be created. A file with this name will be created.
  * \<label>    = Volume Label of the Disk Image visible in DZOS.
  * \<imgsize>  = Disk Image File size in MB (max. 33)
