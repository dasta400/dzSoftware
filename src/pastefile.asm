;******************************************************************************
; Name:         pastefile.asm
; Description:  Transfer files via a Terminal Emulator software.
;               It takes any characters pasted into the terminal, in groups of
;               two bytes, converts the pair into a single hexadecimal byte and
;               saves the byte into the dastaZ80DB's RAM. 
;
;               This program is meant to be used with the dastaZ80DB model or
;               the dastaZ80 (Original) in developer mode (Check the User's
;               Manual for mor details) for transferring files into the
;               computer's memory. It's very handy for testing new software
;               under development.
; Author:       David Asta
; License:      The MIT License
; Created:      20 Oct 2023
; Version:      1.0.0
; Last Modif.:  20 Oct 2023
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
#include "src/equates.inc"
#include "exp/dzOS.exp"
#include "exp/sysvars.exp"
.LIST

;   This program is loaded into a higher RAM address to not use the memory space
;       that will be used by the programs pasted. Usually programs load at $4420
;   dzOS free RAM starts at address 0x4420, and the max. size for a single file
;       is 32,768 (0x8000). Therefore 0x4420 + 0x8000 = 0xC420


        .ORG    $C420                   ; start of code at start of free RAM
        jp      $C425                   ; first instruction must jump to the executable code
        .BYTE   $20, $C4                ; load address (values must be same as .org above)

        .ORG	$C425                   ; start of program (must be same as jp above)

;==============================================================================
; START
;==============================================================================

        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR

; pastefile is invoked with two parameters:
;   1)  start RAM address where the bytes should be written to.
;   2)  total number of bytes to receive (in hexadecimal notation).

        ; Check that both parameter 1 was specified
        ld      A, (CLI_buffer_parm1_val)   ; get what's in param1
        cp      0                           ; was a parameter specified?
        jp      z, bad_params               ; no, show error and exit
        ld      HL, CLI_buffer_parm1_val
        call    convert_param_to_upper
        ; Check that both parameter 2 was specified
        ld      A, (CLI_buffer_parm2_val)   ; get what's in param2
        cp      0                           ; was a parameter specified?
        jp      z, bad_params               ; no, show error and exit
        ld      HL, CLI_buffer_parm2_val
        call    convert_param_to_upper
        
        ; Both parameters specified, continue
        ; convert params from ASCII to hexadecimal
        ld      IX, CLI_buffer_parm1_val    ; start address
        call    F_KRN_ASCIIADR_TO_HEX       ; HL = converted hex value
        push    HL                          ; backup converted start address

        ld      IX, CLI_buffer_parm2_val    ; number of bytes to receive
        call    F_KRN_ASCIIADR_TO_HEX       ; HL = converted hex value
        dec     HL                          ; decrement 1 for zero value of counter

        ; calculate total number of bytes to receive
        ccf                                 ; the total number of bytes 
        adc     HL, HL                      ;   to receive needs to be doubled

        pop     IY                          ; IX = converted start address
        ld      DE, 2                       ; each loop, decrement counter by 2 (a pair)
        ld      B, 32                       ; break line after printing 32 dots
        ccf                                 ; clear Carry flag for next 'sbc' operations
rcv_loop:
        dec     B                           ; if already printed
        jr      nz, no_reset_counter        ;   32 dots:
        ld      B, 32                       ;       reset the counter
        ld      A, CR                       ;       and
        call    F_BIOS_SERIAL_CONOUT_A      ;       jump
        ld      A, LF                       ;       to
        call    F_BIOS_SERIAL_CONOUT_A      ;       next line
no_reset_counter:
        ; receive pairs, convert to single hex byte and store converted in RAM
        push    HL                          ; backup bytes counter
        ;   1st byte
        call    F_BIOS_SERIAL_CONIN_A       ; receive 1st byte
        call    F_KRN_TOUPPER               ; convert to uppercase
        ld      H, A                        ; store it in H
        ld      A, '.'                      ; print a dot to show that a byte
        call    F_BIOS_SERIAL_CONOUT_A      ;   has been received
        ;   2nd byte
        call    F_BIOS_SERIAL_CONIN_A       ; receive 2nd byte
        call    F_KRN_TOUPPER               ; convert to uppercase
        ld      L, A                        ; store it in L
        ld      A, '.'                      ; print a dot to show that a byte
        call    F_BIOS_SERIAL_CONOUT_A      ;   has been received
        ;   convert
        push    BC
        call    F_KRN_ASCII_TO_HEX          ; convert H and L to a hex. byte in A
        pop     BC
        ;   store
        ld      (IY), A                     ; store it in RAM
        inc     IY                          ; point RAM to next address
        ;   loop or exit
        pop     HL                          ; restore bytes counter
        sbc     HL, DE                      ; decrement bytes counter
        jr      nc, rcv_loop                ; repeat until counter = 0

        ld      HL, msg_received
        ld      A, (col_CLI_info)
        call    F_KRN_SERIAL_WRSTR
;------------------------------------------------------------------------------
exitpgm:
        ld      HL, msg_goodbye
        ld      A, (col_CLI_info)
        call    F_KRN_SERIAL_WRSTR
        ld      HL, (CLI_prompt_addr)
        jp      (HL)                    ; return control to CLI
;------------------------------------------------------------------------------
bad_params:
        ld      HL, error_noparams
        ld      A, (col_CLI_error)
        call    F_KRN_SERIAL_WRSTRCLR
        jr      exitpgm
;------------------------------------------------------------------------------
convert_param_to_upper:
; convert the 4 digits of the param pointed by HL to upper
        ld      B, 4
_convert_loop:
        ld      A, (HL)
        call    F_KRN_TOUPPER
        ld      (HL), A
        inc     HL
        djnz    _convert_loop
        ret
;==============================================================================
; Messages
;==============================================================================
msg_welcome:
        .BYTE   CR, LF,
        .BYTE   "pastefile v1.0.0", CR, LF
        .BYTE   "Remember to set a Character delay of 1ms in your Terminal software.", CR, LF
        .BYTE   "Ready to receive.", CR, LF, 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
msg_received:
        .BYTE   CR, LF
        .BYTE   "Data received and stored in RAM.", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_noparams:
        .BYTE   CR, LF
        .BYTE   "Bad parameter(s)", CR, LF, 0
;==============================================================================
; END of CODE
;==============================================================================
        .END
