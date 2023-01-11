;******************************************************************************
; Name:         vdptext.asm
; Description:  Text test.
;               It fills the Name Pattern with hexadecimal values corresponding
;               to printable characters in the ASCII table.
;               It assumes a font was already loaded into the Pattern Table.
; Author:       David Asta
; License:      The MIT License 
; Created:      10 Jan 2023
; Version:      1.0
; Last Modif.:  10 Jan 2023
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2023 David Asta
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
        ld      HL, (VDP_NAMETAB_addr)  ; HL = Name Table address
        call    F_BIOS_VDP_SET_ADDR_WR
        
        ; Print all 256 ASCII Characters
        call    F_BIOS_VDP_DI
        ld      B, 0                    ; will count 256 characters
        ld      A, 0                    ; will start with character $0
_fill_name_table:
        push    AF
        push    BC
        call    F_BIOS_VDP_CHAROUT_ATXY
        pop     BC
        pop     AF
        inc     A
        djnz    _fill_name_table
        call    F_BIOS_VDP_EI

        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR
_main_loop:
        call    F_KRN_SERIAL_RDCHARECHO
        cp      ESC                     ; If it was a ESC
        jp      z, exitpgm              ;   end this program
        call    F_BIOS_VDP_CHAROUT_ATXY
        jr      _main_loop

;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
exitpgm:
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; Messages
;==============================================================================
msg_welcome:
        .BYTE   CR, LF
        .BYTE   "Type some characters. ESC to exit.", CR, LF, 0
err_nomode:
        .BYTE   CR, LF
        .BYTE   "VDP mode is not set in SYSVARS.", 0
err_mode4:
        .BYTE   CR, LF
        .BYTE   "Mode 4 doesn't allow text.", 0

;==============================================================================
; END of CODE
;==============================================================================
        .END