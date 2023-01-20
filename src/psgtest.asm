;******************************************************************************
; Name:         psgtest.asm
; Description:  AY-3-8912 PSG test
;               Adapted from https://www.chibiakumas.com/z80/platform2.php#LessonP18
; Author:       David Asta
; License:      The MIT License
; Created:      20 Jan 2023
; Version:      1.0
; Last Modif.:  20 Jan 2023
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2023
;
; Permission is hereby granted, free of charge, to any person obtaining a copy 
; of this software and associated documentation files (the "Software"), to deal 
; in the Software without restriction, including without limitation the rights 
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
; copies of the Software, and to permit persons to whom the Software is furnished 
; to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all 
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
; -----------------------------------------------------------------------------

.NOLIST
#include "src/_header.inc"              ; This include will add the other needed includes
                                        ; And set the start of code at address $4420
.LIST

;==============================================================================
        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR

        ld      A, 0
        ld      (tmp_byte), A
test_loop:
        ld      A, (SIO_CH_A_LASTCHAR)  ; Get last char stored value
        cp      ESC                     ; If it was a ESC
        jp      z, exitpgm              ;   end this program

        ld      A, (tmp_byte)
        call    make_sound
        ld      BC, $8000
_delay:
        dec     BC
        ld      A, B
        or      C
        jr      nz, _delay

        ld      A, (tmp_byte)
        dec     A
        ld      (tmp_byte), A
        ; Print byte, after 2 backspaces
        ld      A, BSPACE
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, BSPACE
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, (tmp_byte)
        call    F_KRN_SERIAL_PRN_BYTE
        jr      test_loop


; -----------------------------------------------------------------------------
make_sound:
    ; If A = 0, mute sound
        or      A
        jr      z, _silent

    ; Else, prepare PSG
        ld      H, A                    ; backup A

        ; take the three lowest bits of A and set B0, B1, B2 of R0
        and     00000111b
        rrca
        rrca
        rrca
        or      00011111b
        ld      E, A
        ld      A, PSG_R0_CH_A_FTUNE
        call    F_BIOS_PSG_SET_REGISTER

        ; take the three upper bits of A and set B0, B1, B2 of R1
        ld      A, H                    ; restore A
        and     00111000b
        rrca
        rrca
        rrca
        ld      E, A
        ld      A, PSG_R1_CH_A_CTUNE
        call    F_BIOS_PSG_SET_REGISTER

        ; Is the Noise bit set?
        bit     7, H
        jr      z, _make_nonoise        ; No, then skip noise set up

        ; Yes, set up noise
        ld      A, PSG_R7_MIXER
        ld      E, 00110110b            ; Turn On Noise and Tone for Channel A
        call    F_BIOS_PSG_SET_REGISTER
        ld      A, PSG_R6_NOISE_PERIOD
        ld      E, 00011111b
        call    F_BIOS_PSG_SET_REGISTER
        jr      _make_tone

_make_nonoise:
        ld      A, PSG_R7_MIXER
        ld      E, 00111110b            ; Turn On Tone and Off Noise
        call    F_BIOS_PSG_SET_REGISTER

_make_tone:
        ld      A, H                    ; restore A
        and     01000000b               ; Volume bit
        rrca
        rrca
        rrca
        rrca
        or      00001011b
        ld      E, A
        ld      A, PSG_R10_CH_A_AMPL
        call    F_BIOS_PSG_SET_REGISTER

        ret

_silent:
        ld      A, PSG_R7_MIXER
        ld      E, 11111111b            ; Turn off everything
        call    F_BIOS_PSG_SET_REGISTER
        ret

exitpgm:
        call    _silent
        ld      HL, msg_goodbye
        call    F_KRN_SERIAL_WRSTR

;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; Messages
;==============================================================================
msg_welcome:
        .BYTE   CR, LF
        .BYTE   "psgtest - AY-3-8912 (PSG) test.", CR, LF
        .BYTE   "Press ESC to exit", CR, LF
        .BYTE   "    ", 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0

;==============================================================================
; END of CODE
;==============================================================================
        .END