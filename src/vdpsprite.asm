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

;==============================================================================
        call    vdp_init

main_loop:
        ld      A, (SIO_CH_A_LASTCHAR)  ; Get last char stored value
        cp      ESC                     ; If it was a ESC
        jp      z, exitpgm              ;   end this program

        call    check_joystick
        call    player_update
        call    F_BIOS_VDP_VBLANK_WAIT

        jp      main_loop
; -----------------------------------------------------------------------------
vdp_init:
        ; Initialise screen as Graphics II Mode
        call    F_BIOS_VDP_SET_MODE_G2

        ; Set to 16x16 sprites
        ld      A, 1
        ld      B, $C2                  ; 16K, Enable Disp., Disable Int., 16x16 Sprites, Mag. Off
        ; ld      B, $E2                  ; 16K, Enable Disp., Enable Int., 16x16 Sprites, Mag. Off
        call    F_BIOS_VDP_SET_REGISTER

        ; Copy Sprite data to VRAM
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
        call    player_update
        ld      A, (player_attr_patnum)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ld      A, (player_attr_colour)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ret
; -----------------------------------------------------------------------------
player_update:
        ld      HL, VDP_G2_SPRA_TAB
        call    F_BIOS_VDP_SET_ADDR_WR
        ld      A, (player_attr_y)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ld      A, (player_attr_x)
        call    F_BIOS_VDP_BYTE_TO_VRAM
        ret
; -----------------------------------------------------------------------------
check_joystick:
        ld      A, 1                    ; Test Joystick 1
        call    F_BIOS_JOYS_GET_STAT
        cp      JOY_NONE
        ret     z

_joy_test_up:
        bit     0, A
        jp      nz, _joy_up
_joy_test_down:
        bit     1, A
        jp      nz, _joy_down
_joy_test_left:
        bit     2, A
        jp      nz, _joy_left
_joy_test_right:
        bit     3, A
        jp      nz, _joy_right
_joy_test_fire:
        bit     4, A
        jp      nz, _joy_fire
        ret

_joy_up:
        ld      IX, player_attr_y
        dec     (IX)
        ; jp      z, player_at_top        ; Player has reached the top of the screen
        ret
_joy_down:
        ld      IX, player_attr_y
        inc     (IX)
        ret
_joy_left:
        ld      IX, player_attr_x
        dec     (IX)
        ret
_joy_right:
        ld      IX, player_attr_x
        inc     (IX)
        ret
_joy_fire:
        ret

;==============================================================================
; RETURN TO DZOS CLI
;==============================================================================
exitpgm:
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI

;==============================================================================
; Data
;==============================================================================
ship_spr:
        .BYTE   000,000,001,001,001,003,003,007
        .BYTE   007,015,031,063,060,024,000,000
        .BYTE   000,000,128,128,128,192,192,224
        .BYTE   224,240,248,252,060,024,000,000
player_attr_y:
        .BYTE   $FF
player_attr_x:
        .BYTE   $00
player_attr_patnum:
        .BYTE   $00
player_attr_colour:
        .BYTE   $0C

;==============================================================================
; END of CODE
;==============================================================================
        .END