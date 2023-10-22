;******************************************************************************
; Name:         echokbd.asm
; Description:  Prints the hex bytes received from the keyboard
; Author:       David Asta
; License:      The MIT License
; Created:      22 Oct 2023
; Version:      1.0.0
; Last Modif.:  22 Oct 2023
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
; START
;==============================================================================
        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR
        ld      B, 32                   ; break line after printing 32 dots
loop:
        push    BC
        call    F_BIOS_SERIAL_CONIN_A   ; read character from keyboard
        cp      ESC                     ; if pressed key was ESC
        jp      z, exitpgm              ;   exit. Otherwise continue.

        call    F_KRN_HEX_TO_ASCII      ; convert A into ASCII in HL
        ld      A, H                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   MSB
        ld      A, L                    ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   LSB
        ld      A, SPACE                ; print
        call    F_BIOS_SERIAL_CONOUT_A  ;   a space seprator
        pop     BC
        djnz    loop                    ; repeat
        ld      B, 32                   ; break line after printing 32 dots
        ld      A, CR                   ;
        call    F_BIOS_SERIAL_CONOUT_A  ;
        ld      A, LF                   ;
        call    F_BIOS_SERIAL_CONOUT_A  ;
        jr      loop



exitpgm:
        ld      HL, msg_goodbye
        ld      A, (col_CLI_info)
        call    F_KRN_SERIAL_WRSTR
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI
;==============================================================================
; Messages
;==============================================================================
msg_welcome:
        .BYTE   CR, LF,
        .BYTE   "echokbd v1.0.1", CR, LF
        .BYTE   "Start typing characters. Press ESC to exit", CR, LF, 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
;==============================================================================
; END of CODE
;==============================================================================
        .END