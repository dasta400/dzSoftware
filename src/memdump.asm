;******************************************************************************
; Name:         memdump.asm
; Description:  Shows contents (bytes) of a specified section (range) of RAM.
; Author:       David Asta
; License:      The MIT License 
; Created:      20 June 2019
; Version:      1.0
; Last Modif.:  20 June 2019
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

LINESPERPAGE    .EQU    20              ; 20 lines per page (for memdump)
buffer          .EQU    tmp_addr1       ; buffer for addresses entered by user

        ld      IX, buffer              ; IX = pointer to buffer address
        ld      HL, msg_welcome
        call    F_KRN_SERIAL_WRSTR
askaddresses:
        ; ask for start_address
        ld      HL, msg_askstartaddr
        call    F_KRN_SERIAL_WRSTR
        ; get 1st (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        cp      CR                      ; user entered a CR?
        jp      z, exitpgm              ; yes, exit program
        ld      (IX + 0), A             ; store character in buffer
        ; get 2nd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (IX + 1), A             ; store character in buffer
        ; get 3rd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (IX + 2), A             ; store character in buffer
        ; get 4th (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (IX + 3), A             ; store character in buffer

        ; ask for end_address
        ld      HL, msg_askendaddr
        call    F_KRN_SERIAL_WRSTR
        ; get 1st (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        cp      CR                      ; user entered a CR?
        jp      z, exitpgm              ; yes, exit program
        ld      (IX + 4), A             ; store character in buffer
        ; get 2nd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (IX + 5), A             ; store character in buffer
        ; get 3rd (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (IX + 6), A             ; store character in buffer
        ; get 4th (out of 4) character
        call    F_KRN_SERIAL_RDCHARECHO
        ld      (IX + 7), A             ; store character in buffer

        ; print header
        ld      HL, msg_memdump_hdr
        call    F_KRN_SERIAL_WRSTR
        ; IX (4 to 7) have the end_address value in hexadecimal
        ; need to convert it to binary
        ld      A, (IX + 4)
        ld      H, A
        ld      A, (IX + 5)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      D, A
        ld      A, (IX + 6)
        ld      H, A
        ld      A, (IX + 7)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      E, A
        ; DE contains the binary value for end_address
        push    DE                      ; store it in the stack
        ; IX (0 to 3) have the start_address value in hexadecimal
        ; need to convert it to binary
        ld      A, (IX + 0)
        ld      H, A
        ld      A, (IX + 1)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      D, A
        ld      A, (IX + 2)
        ld      H, A
        ld      A, (IX + 3)
        ld      L, A
        call    F_KRN_ASCII_TO_HEX
        ld      E, A
        ; DE contains the binary value for start_address
        ex      DE, HL                  ; HL = start_address
        pop     DE                      ; DE = end_address
start_dump_line:
        ld      C, LINESPERPAGE         ; we will print 23 lines per page
dump_line:
        push    HL
        ld      A, CR
        call    F_BIOS_SERIAL_CONOUT_A
        ld      A, LF
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_KRN_SERIAL_PRN_WORD
        ld      a, ':'                  ; semicolon separates mem address from data
        call    F_BIOS_SERIAL_CONOUT_A
        ld      a, ' '                  ; and an extra space to separate
        call    F_BIOS_SERIAL_CONOUT_A
        ld      b, $10                  ; we will output 16 bytes in each line
dump_loop:
        ld      A, (HL)
        call    F_KRN_SERIAL_PRN_BYTE
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        inc     HL
        djnz    dump_loop
        ; dump ASCII characters
        pop     HL
        ld      B, $10                  ; we will output 16 bytes in each line
        ld      A, ' '
        call    F_BIOS_SERIAL_CONOUT_A
        call    F_BIOS_SERIAL_CONOUT_A
ascii_loop:
        ld      A, (HL)                 ; is it an ASCII printable character?
        call    F_KRN_IS_PRINTABLE
        jr      c, printable
        ld      A, '.'                  ; if is not, print a dot
printable:
        call    F_BIOS_SERIAL_CONOUT_A
        inc     HL
        djnz    ascii_loop

        push    HL                      ; backup HL before doing sbc instruction
        and     A                       ; clear carry flag
        sbc     HL, DE                  ; have we reached the end address?
        pop     HL                      ; restore HL
        jr      c, dump_next            ; end address not reached. Dump next line
        jp      askaddresses            ; end address reached. Ask for new addresses
dump_next:
        dec     C                       ; 1 line was printed
        jp      z, askmoreorquit        ; we have printed 23 lines. More?
        jp      dump_line               ; print another line
askmoreorquit:
        push    HL                      ; backup HL
        ld      HL, msg_moreorquit
        call    F_KRN_SERIAL_WRSTR
        call    F_BIOS_SERIAL_CONIN_A   ;read key
        cp      SPACE                   ; was the SPACE key?
        jp      z, wantsmore            ; user wants more
        pop     HL                      ; yes, user wants more. Restore HL
        jp      askaddresses            ; no, ask for new addresses
wantsmore:
        ; print header
        ld      HL, msg_memdump_hdr
        call    F_KRN_SERIAL_WRSTR
        pop     HL                      ; restore HL
        jp      start_dump_line         ; return to start, so we print 23 more lines
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
        .BYTE   "memdump - Shows contents of a range in RAM.", 0
msg_goodbye:
        .BYTE   CR, LF
        .BYTE   "Goodbye!", 0
msg_askstartaddr:
        .BYTE   CR, LF, CR, LF
        .BYTE   "Start Address? (blank to exit program) ", 0
msg_askendaddr:
        .BYTE   CR, LF
        .BYTE   "End Address? ", 0
msg_memdump_hdr:
        .BYTE   CR, LF, CR, LF
        .BYTE   "      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", CR, LF
        .BYTE   "      .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..", 0
msg_moreorquit:
        .BYTE   CR, LF
        .BYTE   "[SPACE] for more or another key for stop.", 0
msg_error_noendaddr:
        .BYTE   CR, LF
        .BYTE   "ERROR: End Address was not specified."

        .END