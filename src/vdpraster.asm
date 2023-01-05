;******************************************************************************
; Name:         vdpraster.asm
; Description:  VDP Interrupts test
;               Run before and after disabling VDP interrupts to see the effect
; Author:       David Asta
; License:      The MIT License 
; Created:      05 Jan 2023
; Version:      1.0
; Last Modif.:  05 Jan 2023
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
        ld      A, VDP_COLR_M_GRN
        ld      (colour), A
loop:
        call    F_BIOS_VDP_VBLANK_WAIT

        ld      HL, colour
        inc     (HL)
        ld      A, 7
        ld      B, (HL)
        call    F_BIOS_VDP_SET_REGISTER

        jr      loop                    ; Runs infinitely. No return to CLI

;==============================================================================
; Data
;==============================================================================

colour:
        .BYTE   0

;==============================================================================
; END of CODE
;==============================================================================
        .END