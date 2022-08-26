;; FILE: crt0.s
;; Generic crt0.s for a Z80
;; From SDCC..
;; Modified to suit execution on the dastaZ80

    .module crt0
    .globl  _main

    .area   _HEADER (ABS)
;; Reset vector
    .org    0x4420 ;; Start from address 0x4420 (start of dastaZ80 free RAM)
    jp      init
    .db     0x20, 0x44

    .org    0x4430

init:

;; Initialise global variables
    call    gsinit
    call    _main
    jp      _exit

    ;; Ordering of segments for the linker.
    .area   _HOME
    .area   _CODE
    .area   _GSINIT
    .area   _GSFINAL

    .area   _DATA
    .area   _BSS
    .area   _HEAP

    .area   _CODE
__clock::
    ret

_exit::
    jp      0x278D  ;; Go back to dzOS CLI

    .area   _GSINIT
gsinit::

    .area   _GSFINAL
    ret