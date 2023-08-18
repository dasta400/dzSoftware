;******************************************************************************
; Name:         vdpsetmode.asm
; Description:  Changes the VDP mode acording to parameter received
;               0=Text Mode, 1=Graphics I Mode, 2=Graphics II Mode,
;               3=Multicolour Mode, 4=Graphics II Mode Bitmapped
;
; Author:       David Asta
; License:      The MIT License 
; Created:      07 Jan 2023
; Version:      1.0
; Last Modif.:  18 Aug 2023
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
        ; Check parameter is numeric
        ld      HL, CLI_buffer_parm1_val  ; parameter entered by user
        ld      A, (HL)                 ; get the byte
        call    F_KRN_IS_NUMERIC        ; and check  if it's a number (C Flag set)
        jp      nc, _error_param        ; if no numeric, error

        cp      $30
        jp      z, _set_mode0
        cp      $31
        jp      z, _set_mode1
        cp      $32
        jp      z, _set_mode2
        cp      $33
        jp      z, _set_mode3
        cp      $34
        jp      z, _set_mode4
        
        ld      HL, err_mode
        call    F_KRN_SERIAL_WRSTR
        jr      exitpgm


_set_mode0:
        call    F_BIOS_VDP_SET_MODE_TXT
        jr      exitpgm
_set_mode1:
        call    F_BIOS_VDP_SET_MODE_G1
        jr      exitpgm
_set_mode2:
        call    F_BIOS_VDP_SET_MODE_G2
        jr      exitpgm
_set_mode3:
        call    F_BIOS_VDP_SET_MODE_MULTICLR
        jr      exitpgm
_set_mode4:
        call    F_BIOS_VDP_SET_MODE_G2BM
        jr      exitpgm

_error_param:
        ld      HL, err_param
        call    F_KRN_SERIAL_WRSTR

;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
exitpgm:
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; Messages
;==============================================================================
err_param:
        .BYTE   CR, LF
        .BYTE   "Parameter missing or it was not a number.", 0
err_mode:
        .BYTE   CR, LF
        .BYTE   "Mode number incorrect. Valid modes 0 to 4.", 0

;==============================================================================
; END of CODE
;==============================================================================
        .END