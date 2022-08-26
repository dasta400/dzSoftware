;; FILE: putchar.s
;; Modified to suit execution on the dastaZ80

; sdcc Calling conventions
;   By default, all parameters are passed on the stack, right-to-left. 
;   8-bit return values are passed in l
;   16-bit values in hl
;   32-bit values in dehl

    .area _CODE
_putchar::
_putchar_rr_s::
    ld      hl, #2      ; HL points to SP+2 (place where parameters start)
    add     hl, sp

    ld      a, (hl)     ; A = character to output
    call    0x134C      ; F_BIOS_SERIAL_CONOUT_A
    ret

_putchar_rr_dbs::
    ld      a, e        ; A = character to output
    call    0x134C      ; F_BIOS_SERIAL_CONOUT_A
    ret