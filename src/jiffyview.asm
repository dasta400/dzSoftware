;******************************************************************************
; Name:         jiffyview.asm
; Description:  Shows current values of Jiffies bytes
; Author:       David Asta
; License:      The MIT License 
; Created:      26 Dec 2022
; Version:      1.0
; Last Modif.:  26 Dec 2022
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2022 David Asta
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

        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR

_showvalues:
        ; Show values
        ld      B, 1
        call    F_KRN_SERIAL_EMPTYLINES
        
        ld      A, (VDP_jiffy_byte1)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A

        ld      A, (VDP_jiffy_byte2)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A

        ld      A, (VDP_jiffy_byte3)
        call    F_KRN_SERIAL_PRN_BYTE

        ; Wait for key press
        call    F_BIOS_SERIAL_CONIN_A
        cp      CR                      ; if pressed key was RETURN, exit
        jp      nz, _showvalues         ; else, show more values

exitpgm:
        ld      HL, msg_goodbye
        call    F_KRN_SERIAL_WRSTR
;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
; To return to CLI, jump to the address stored at SYSVARS.CLI_prompt_addr
; This ensure that any changes in the Operating System won't affect your program
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; Messages
;==============================================================================
msg_welcome:
        .BYTE   CR, LF, CR, LF
        .BYTE   "jiffyview - Shows current values of Jiffies bytes.", 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
msg_presskey:
        .BYTE   CR, LF
        .BYTE   "Press any key more more values or RETURN to exit.", 0

;==============================================================================
; END of CODE
;==============================================================================
        .END