;******************************************************************************
; Name:         testkeys.asm
; Description:  Test SYSVARS.SIO_CH_A_LASTCHAR
; Author:       David Asta
; License:      The MIT License
; Created:      31 Dec 2022
; Version:      1.0
; Last Modif.:  31 Dec 2022
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2022
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

        ; Reset Lastchar and tmp_byte variables
        ld      A, 0
        ld      (SIO_CH_A_LASTCHAR), A
        ld      (tmp_byte), A
        ; call    F_BIOS_VDP_VBLANK_WAIT
        ld      IX, tmp_byte            ; IX = pointer to tmp_byte
_loop:
        ld      A, (SIO_CH_A_LASTCHAR)  ; Get last char stored value
        cp      (IX)                    ; If last char is equal to previous
        jp      z, _loop                ;   wait until is different

        ld      HL, msg_lastkey
        call    F_KRN_SERIAL_WRSTR
        ld      A, (SIO_CH_A_LASTCHAR)  ; Get last char stored value
        ; cp      0
        ; jp      z, _loop
        ld      (IX), A                 ; Store it in tmp_byte
        call    F_KRN_SERIAL_PRN_BYTE   ; and print it

        ld      A, (SIO_CH_A_LASTCHAR)  ; Get last char stored value
        cp      ESC                     ; If it was a ESC
        ; jp      z, exitpgm              ;   end this program

        ; ld      (IX), 0
        ; jp      _loop
        jp      nz, _loop

exitpgm:
        call    F_KRN_SERIAL_CLR_SIOCHA_BUFFER
        ld      HL, msg_goodbye
        call    F_KRN_SERIAL_WRSTR
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; Messages
;==============================================================================
msg_welcome:
        .BYTE   CR, LF, CR, LF
        .BYTE   "testkeys - Test SYSVARS.SIO_CH_A_LASTCHAR.", CR, LF
        .BYTE   "Press any ESC to exit.", CR, LF, 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
msg_lastkey:
        .BYTE   CR, LF
        .BYTE   "Key: ", 0

;==============================================================================
; END of CODE
;==============================================================================
        .END