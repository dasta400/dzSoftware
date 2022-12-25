;******************************************************************************
; Name:         vdpsprite.asm
; Description:  Sprite test
; Author:       David Asta
; License:      The MIT License 
; Created:      25 Dec 2022
; Version:      1.0
; Last Modif.:  25 Dec 2022
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; Copyright (C) 2018 David Asta
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
        ; Initialise screen as Graphics II Mode
        call    F_BIOS_VDP_SET_MODE_G2

        ; Set to 16x16 sprites
        ld      A, 1
        ld      B, $C2                  ; 16K, Enable Disp., Disable Int., 16x16 Sprites, Mag. Off
        call    F_BIOS_VDP_SET_REGISTER

        ; Copy Sprite date to VRAM
        ld      HL, VDP_G2_SPRP_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      IX, ship_spr
        ld      B, 32
_spr_to_patt_tab:
        ld      A, (IX)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        inc     IX
        djnz    _spr_to_patt_tab

        ; Set Sprite Attribute Table
        ld      HL, VDP_G2_SPRA_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      IX, ship_spr_attr
        ld      A, (IX)                 ; Y position
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ld      A, (IX + 1)             ; X position
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ld      A, (IX + 2)             ; Sprite name pointer
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ld      A, (IX + 3)             ; Colour
        call    F_BIOS_VDP_BYTE_TO_VRAM

;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
; To return to CLI, jump to the address stored at SYSVARS.CLI_prompt_addr
; This ensure that any changes in the Operating System won't affect your program
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

ship_spr:
        .BYTE   000,000,001,001,001,003,003,007
        .BYTE   007,015,031,063,060,024,000,000
        .BYTE   000,000,128,128,128,192,192,224
        .BYTE   224,240,248,252,060,024,000,000
ship_spr_attr:
        .BYTE   64, 64, 0, $0C          ; y, x, pattern #, colour


;==============================================================================
; END of CODE
;==============================================================================
        .END