;******************************************************************************
; Name:         testjoys.asm
; Description:  Test Dual Digital Joystick Port
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
        jp      _main_loop

_delay:
        ld      A, 255
_delay_loop:
        dec     A
        jp      nz, _delay_loop

_main_loop:
        ld      A, (SIO_CH_A_LASTCHAR)  ; Get last char stored value
        cp      ESC                     ; If it was a ESC
        jp      z, exitpgm              ;   end this program

_test_joy1:
        ld      A, 1                    ; Test Joystick 1
        call    F_BIOS_JOYS_GET_STAT
        cp      JOY_NONE
        jp      z, _test_joy2

        push    AF                      ; Backup Joystick Stat (A)
        ld      HL, msg_joy1            ;   because F_KRN_SERIAL_WRSTR destroys it
        call    F_KRN_SERIAL_WRSTR
        jp      _joy_button

_test_joy2:
        ld      A, 2                    ; Test Joystick 2
        call    F_BIOS_JOYS_GET_STAT
        cp      JOY_NONE
        jp      z, _delay

        push    AF                      ; Backup Joystick Stat (A)
        ld      HL, msg_joy2            ;   because F_KRN_SERIAL_WRSTR destroys it
        call    F_KRN_SERIAL_WRSTR

_joy_button:
        pop     AF                      ; Restore Joystick Stat
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
        jp      _delay

_joy_up:
        push    AF                      ; Backup Joystick Stat
        ld      HL, msg_joy_up
        call    F_KRN_SERIAL_WRSTR
        pop     AF                      ; Restore Joystick Stat
        jp      _joy_test_down          ; Test other buttons
_joy_down:
        push    AF                      ; Backup Joystick Stat
        ld      HL, msg_joy_dn
        call    F_KRN_SERIAL_WRSTR
        pop     AF                      ; Restore Joystick Stat
        jp      _joy_test_left          ; Test other buttons
_joy_left:
        push    AF                      ; Backup Joystick Stat
        ld      HL, msg_joy_lt
        call    F_KRN_SERIAL_WRSTR
        pop     AF                      ; Restore Joystick Stat
        jp      _joy_test_right         ; Test other buttons
_joy_right:
        push    AF                      ; Backup Joystick Stat
        ld      HL, msg_joy_rt
        call    F_KRN_SERIAL_WRSTR
        pop     AF                      ; Restore Joystick Stat
        jp      _joy_test_fire          ; Test other buttons
_joy_fire:
        push    AF                      ; Backup Joystick Stat
        ld      HL, msg_joy_fe
        call    F_KRN_SERIAL_WRSTR
        pop     AF                      ; Restore Joystick Stat
        jp      _delay                  ; Test other buttons

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
        .BYTE   "testjoys - Test Dual Digital Joystick Port.", CR, LF, 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
msg_empty_line:
        .BYTE   CR, LF
msg_joy1:
        .BYTE   "Joystick 1 - ", 0
msg_joy2:
        .BYTE   "Joystick 2 - ", 0
msg_joy_up:
        .BYTE   "UP", CR, LF, 0
msg_joy_dn:
        .BYTE   "DOWN", CR, LF, 0
msg_joy_lt:
        .BYTE   "LEFT", CR, LF, 0
msg_joy_rt:
        .BYTE   "RIGHT", CR, LF, 0
msg_joy_fe:
        .BYTE   "FIRE", CR, LF, 0

;==============================================================================
; END of CODE
;==============================================================================
        .END